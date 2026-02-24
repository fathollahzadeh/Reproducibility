
WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE Reputation > 1000
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND p.PostTypeId IN (1, 2) 
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
TagEngagement AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsTagged,
        SUM(ps.ViewCount) AS TotalViews,
        AVG(ps.Score) AS AverageScore
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    JOIN PostStatistics ps ON p.Id = ps.PostId
    GROUP BY t.TagName
),
BadgeStatistics AS (
    SELECT 
        b.Name AS BadgeName,
        COUNT(DISTINCT b.UserId) AS TotalAwarded,
        COUNT(DISTINCT u.Id) AS UsersWithBadge
    FROM Badges b
    JOIN Users u ON b.UserId = u.Id
    GROUP BY b.Name
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ps.Title,
    ps.Score,
    ps.TotalComments,
    ps.TotalVotes,
    te.TagName,
    te.PostsTagged,
    te.TotalViews,
    te.AverageScore,
    bs.BadgeName,
    bs.TotalAwarded,
    bs.UsersWithBadge
FROM UserReputation ur
JOIN PostStatistics ps ON ur.Id = ps.PostId
JOIN TagEngagement te ON te.PostsTagged > 0
JOIN BadgeStatistics bs ON bs.UsersWithBadge > 0
ORDER BY ur.Reputation DESC, ps.Score DESC;
