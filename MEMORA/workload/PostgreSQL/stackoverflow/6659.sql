
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        pt.Name AS PostTypeName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.Score > 0
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerName,
        tp.PostTypeName,
        CASE 
            WHEN tp.PostRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        tp.OwnerUserId
    FROM TopPosts tp
)
SELECT 
    ru.DisplayName AS UserName,
    ru.Reputation,
    COUNT(pd.PostId) AS TotalPosts,
    SUM(pd.ViewCount) AS TotalViews,
    AVG(pd.Score) AS AveragePostScore,
    MAX(pd.CreationDate) AS LastPostDate
FROM RankedUsers ru
JOIN PostDetails pd ON ru.UserId = pd.OwnerUserId
GROUP BY ru.UserId, ru.DisplayName, ru.Reputation
HAVING COUNT(pd.PostId) > 1
ORDER BY ru.Reputation DESC, TotalViews DESC
LIMIT 10;
