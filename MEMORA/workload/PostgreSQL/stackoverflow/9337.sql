WITH AvgUserReputation AS (
    SELECT AVG(Reputation) AS AvgReputation
    FROM Users
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    ORDER BY p.Score DESC
    LIMIT 5
),
RecentPostHistory AS (
    SELECT ph.PostId, p.Title, p.CreationDate, p.OwnerDisplayName, p.ViewCount, p.Score, 
           COUNT(*) AS EditCount, MIN(ph.CreationDate) AS FirstEditDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY ph.PostId, p.Title, p.CreationDate, p.OwnerDisplayName, p.ViewCount, p.Score
),
BadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)
SELECT 
    t.Title AS TopPostTitle,
    t.OwnerDisplayName AS TopPostOwner,
    t.Score AS TopPostScore,
    t.ViewCount AS TopPostViews,
    r.EditCount AS RecentEditCount,
    r.FirstEditDate AS FirstRecentEditDate,
    b.BadgeCount AS OwnerBadgeCount,
    a.AvgReputation AS AverageUserReputation
FROM TopPosts t
LEFT JOIN RecentPostHistory r ON t.Id = r.PostId
LEFT JOIN BadgeCounts b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.Id)
CROSS JOIN AvgUserReputation a;