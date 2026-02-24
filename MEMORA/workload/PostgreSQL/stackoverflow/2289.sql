WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    COALESCE(PS.TotalPosts, 0) AS PostsPublished,
    COALESCE(PS.QuestionsCount, 0) AS QuestionsAsked,
    COALESCE(PS.AnswersCount, 0) AS AnswersGiven,
    UR.Reputation,
    CASE 
        WHEN UR.Reputation > 10000 THEN 'Expert'
        WHEN UR.Reputation BETWEEN 5000 AND 10000 THEN 'Pro'
        ELSE 'Newbie'
    END AS UserLevel,
    CASE 
        WHEN PS.TotalViewCount IS NULL THEN 'No Views'
        WHEN PS.TotalViewCount > 0 AND PS.TotalViewCount <= 100 THEN 'Low Engagement'
        WHEN PS.TotalViewCount > 100 AND PS.TotalViewCount <= 1000 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM UserReputation UR
LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
WHERE UR.Reputation > 1000
ORDER BY UR.Reputation DESC
LIMIT 10;