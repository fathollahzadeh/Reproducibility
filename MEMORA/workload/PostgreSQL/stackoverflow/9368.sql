
WITH RankedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopScored AS (
    SELECT PostId, Title, Score, ViewCount, CreationDate, OwnerUserId
    FROM RankedPosts
    WHERE ScoreRank <= 10
),
TopViewed AS (
    SELECT PostId, Title, Score, ViewCount, CreationDate, OwnerUserId
    FROM RankedPosts
    WHERE ViewRank <= 10
)
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.CreationDate AS PostCreationDate,
    'Top Scored' AS Category
FROM TopScored p
JOIN Users u ON p.OwnerUserId = u.Id
UNION ALL
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.CreationDate AS PostCreationDate,
    'Top Viewed' AS Category
FROM TopViewed p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY Category, PostScore DESC;
