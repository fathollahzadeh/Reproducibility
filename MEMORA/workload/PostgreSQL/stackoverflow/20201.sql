
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
TopCommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
    HAVING 
        COUNT(c.Id) > 5  
),
DistinctTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT TRIM(value)) AS TagCount
    FROM 
        Posts p,
        UNNEST(string_to_array(p.Tags, '<>')) AS value
    GROUP BY 
        p.Id
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ub.BadgeCount,
    ub.BadgeNames,
    tc.CommentCount,
    dt.TagCount,
    rcp.LastClosed
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
LEFT JOIN 
    TopCommentedPosts tc ON rp.PostId = tc.PostId
LEFT JOIN 
    DistinctTagCounts dt ON rp.PostId = dt.PostId
LEFT JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.PostId
WHERE 
    rp.Rank <= 10 
    AND rp.Score > 0 
    AND dt.TagCount IS NOT NULL 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
