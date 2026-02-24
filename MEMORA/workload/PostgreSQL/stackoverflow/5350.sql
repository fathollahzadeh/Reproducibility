WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           u.DisplayName AS OwnerName, 
           p.ViewCount, 
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT rp.OwnerName, 
           COUNT(rp.Id) AS TotalPosts, 
           AVG(rp.ViewCount) AS AvgViews, 
           SUM(rp.Score) AS TotalScore
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
    GROUP BY rp.OwnerName
),
BadgedUsers AS (
    SELECT u.Id, 
           u.DisplayName, 
           COUNT(*) AS BadgeCount
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(*) > 5
),
TopContributors AS (
    SELECT pu.OwnerName, 
           ps.TotalPosts, 
           ps.AvgViews, 
           ps.TotalScore, 
           bu.BadgeCount
    FROM PostStatistics ps
    JOIN RankedPosts pu ON ps.OwnerName = pu.OwnerName
    JOIN BadgedUsers bu ON pu.OwnerName = bu.DisplayName
)
SELECT OwnerName, 
       TotalPosts, 
       AvgViews, 
       TotalScore, 
       BadgeCount
FROM TopContributors
ORDER BY TotalScore DESC, AvgViews DESC;