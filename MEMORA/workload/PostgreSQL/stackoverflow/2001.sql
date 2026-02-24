WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(b.Id) > 3
)
SELECT 
    up.DisplayName,
    tp.Title AS TopPostTitle,
    tp.Score,
    tp.ViewCount,
    ub.BadgeCount
FROM 
    Users up
JOIN 
    TopPosts tp ON tp.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = up.Id
    )
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
WHERE 
    up.Reputation > 500
ORDER BY 
    tp.Score DESC, 
    up.Reputation DESC
LIMIT 100;