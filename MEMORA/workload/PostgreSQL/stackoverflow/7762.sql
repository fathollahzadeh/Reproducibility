WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(UP.NumPosts, 0) AS NumPosts,
        COALESCE(UP.NumAnswers, 0) AS NumAnswers,
        COALESCE(UP.NumComments, 0) AS NumComments,
        COALESCE(B.NumBadges, 0) AS NumBadges
    FROM Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS NumPosts,
            SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS NumAnswers,
            SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS NumQuestions,
            SUM(CASE WHEN PostTypeId NOT IN (1,2) THEN 1 ELSE 0 END) AS NumComments  
        FROM Posts 
        GROUP BY OwnerUserId
    ) UP ON U.Id = UP.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS NumBadges
        FROM Badges 
        GROUP BY UserId
    ) B ON U.Id = B.UserId
), UserActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS ActivityCount,
        MAX(CreationDate) AS LastActivityDate
    FROM (
        SELECT UserId, CreationDate FROM Votes
        UNION ALL
        SELECT UserId, CreationDate FROM Comments
        UNION ALL
        SELECT OwnerUserId AS UserId, CreationDate FROM Posts
    ) AS Activities
    GROUP BY UserId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.NumPosts,
    US.NumAnswers,
    US.NumComments,
    US.NumBadges,
    UA.ActivityCount,
    UA.LastActivityDate
FROM UserScores US
JOIN UserActivity UA ON US.UserId = UA.UserId
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, UA.ActivityCount DESC
LIMIT 100;