
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id,
        u.DisplayName,
        u.Reputation
    HAVING 
        AVG(u.Reputation) > 1000 OR COUNT(b.Id) > 5
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.BadgeCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE CASE 
            WHEN rp.Score > 10 THEN 'Highly Rated'
            ELSE 'Moderately Rated'
        END
    END AS RatingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
JOIN 
    FilteredUsers f ON f.UserId = rp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 50;
