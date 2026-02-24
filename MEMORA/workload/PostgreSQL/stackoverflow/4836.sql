
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedTime
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cb.LastClosedTime, NULL) AS LastClosedTime,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cb ON rp.PostId = cb.PostId
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank <= 5  
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    LastClosedTime,
    BadgeCount
FROM 
    FinalResults
WHERE 
    (LastClosedTime IS NULL OR LastClosedTime < CURRENT_DATE - INTERVAL '6 months')
ORDER BY 
    Score DESC;
