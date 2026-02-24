
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, U.DisplayName
),
TopScoringPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore = 1
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.OwnerDisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    CONCAT('Post ID: ', CAST(ps.Id AS VARCHAR), ' | Score: ', CAST(ps.Score AS VARCHAR)) AS PostSummary,
    CASE 
        WHEN ps.Score > 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopScoringPosts ps
LEFT JOIN 
    UserBadges ub ON ps.OwnerUserId = ub.UserId
ORDER BY 
    ps.Score DESC
LIMIT 10;
