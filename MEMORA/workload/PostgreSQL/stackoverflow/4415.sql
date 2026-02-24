
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year') 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.TotalPosts,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount
FROM 
    UserRankings ur
JOIN 
    TopPosts tp ON ur.TotalPosts > 0
ORDER BY 
    ur.TotalPosts DESC, tp.Score DESC
LIMIT 10;
