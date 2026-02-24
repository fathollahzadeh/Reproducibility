WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 10000 THEN 'Expert'
            WHEN u.Reputation >= 1000 THEN 'Intermediate'
            ELSE 'Novice'
        END AS ReputationLevel
    FROM Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(u.Reputation, 0) AS Reputation,
    COALESCE(PostStats.TotalPosts, 0) AS TotalPosts,
    COALESCE(PostStats.Questions, 0) AS TotalQuestions,
    COALESCE(PostStats.Answers, 0) AS TotalAnswers,
    COALESCE(PostStats.AverageScore, 0) AS AvgPostScore,
    COALESCE(UserBadges.BadgeNames, 'No Badges') AS Badges,
    UserReputation.ReputationLevel
FROM Users u
LEFT JOIN PostStats ON u.Id = PostStats.OwnerUserId
LEFT JOIN UserBadges ON u.Id = UserBadges.UserId
LEFT JOIN UserReputation ON u.Id = UserReputation.UserId
WHERE COALESCE(PostStats.TotalPosts, 0) > 0
  AND UserReputation.ReputationLevel = 'Expert'
ORDER BY TotalPosts DESC
LIMIT 10;
