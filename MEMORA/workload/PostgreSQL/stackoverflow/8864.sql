
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount,
        MAX(u.CreationDate) AS AccountCreationDate,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - c.CreationDate)) / 60) AS AvgTimeToEngagement
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.QuestionsCount,
    us.AnswersCount,
    us.AcceptedAnswersCount,
    us.AccountCreationDate,
    us.AvgTimeToEngagement,
    b.Name AS BadgeName,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM UserStatistics us
LEFT JOIN Badges b ON us.UserId = b.UserId
WHERE us.Reputation > 1000 
GROUP BY us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.QuestionsCount, us.AnswersCount, us.AcceptedAnswersCount, us.AccountCreationDate, us.AvgTimeToEngagement, b.Name
ORDER BY us.Reputation DESC, us.TotalPosts DESC
LIMIT 50;
