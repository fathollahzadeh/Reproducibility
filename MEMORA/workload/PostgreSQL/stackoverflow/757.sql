WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate, 
        LastAccessDate, 
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
), 
PostStatistics AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
), 
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivity,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.ReputationLevel,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.Questions, 0) AS Questions,
    COALESCE(ps.Answers, 0) AS Answers,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    ra.LastActivity,
    ra.CommentCount
FROM UserReputation u
LEFT JOIN PostStatistics ps ON u.UserId = ps.OwnerUserId
LEFT JOIN RecentActivity ra ON u.UserId = ra.OwnerUserId
WHERE u.CreationDate >= '2020-01-01'
ORDER BY u.Reputation DESC, TotalPosts DESC
LIMIT 10;