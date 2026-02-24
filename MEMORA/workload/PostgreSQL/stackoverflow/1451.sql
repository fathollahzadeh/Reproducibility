
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
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
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rb.BadgeCount,
        rb.HighestBadgeClass,
        pc.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rb.BadgeCount, rb.HighestBadgeClass, pc.CommentCount
)

SELECT 
    pg.PostId,
    pg.Title,
    pg.Score,
    pg.BadgeCount,
    pg.HighestBadgeClass,
    pg.CommentCount,
    pg.NetVotes,
    PHT.Name AS PostHistoryTypeName
FROM 
    CombinedData pg
LEFT JOIN 
    PostHistory ph ON pg.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
WHERE 
    pg.Score > 0 AND 
    (pg.BadgeCount IS NULL OR pg.BadgeCount > 5) 
ORDER BY 
    pg.Score DESC, pg.CommentCount DESC;
