
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ub.BadgeCount,
        ub.BadgeList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.OwnerUserId IS NOT NULL
        )
    WHERE 
        rp.Rank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    COALESCE(pp.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pp.BadgeList, 'No badges') AS Badges
FROM 
    PopularPosts pp
LEFT JOIN 
    Users u ON pp.PostId = u.Id 
WHERE 
    u.Reputation >= 1000
ORDER BY 
    pp.Score DESC
LIMIT 10;
