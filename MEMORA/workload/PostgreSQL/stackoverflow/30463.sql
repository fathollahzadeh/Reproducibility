
WITH RecursivePosts AS (
    SELECT p.Id, p.Title, p.PostTypeId, p.OwnerUserId, p.CreationDate,
           ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
),
UserPostActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           MAX(COALESCE(p.CreationDate, '1900-01-01')) AS LatestPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT ph.PostId, COUNT(ph.Id) AS RevisionCount,
           SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount,
           ROW_NUMBER() OVER(ORDER BY p.Score DESC) AS RankByScore,
           p.OwnerUserId
    FROM Posts p
    WHERE p.PostTypeId = 1
)
SELECT u.DisplayName,
       up.TotalPosts,
       up.TotalAnswers,
       up.LatestPostDate,
       pp.Title AS TopPostTitle,
       pp.Score AS TopPostScore,
       phs.RevisionCount,
       phs.CloseReopenCount,
       CASE 
           WHEN up.LatestPostDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') THEN 'Active'
           ELSE 'Inactive'
       END AS ActivityStatus
FROM UserPostActivity up
LEFT JOIN TopPosts pp ON up.UserId = pp.OwnerUserId AND pp.RankByScore = 1
LEFT JOIN PostHistoryStats phs ON pp.Id = phs.PostId
JOIN Users u ON up.UserId = u.Id
WHERE up.TotalPosts > 0
ORDER BY up.TotalAnswers DESC, up.TotalPosts DESC;
