
WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        LastAccessDate, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
), 
UserActivity AS (
    SELECT 
        UR.Id AS UserId,
        UR.DisplayName,
        COALESCE(PS.QuestionsCount, 0) AS TotalQuestions,
        COALESCE(PS.AnswersCount, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        UR.LastAccessDate,
        UR.ReputationRank
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.Id = PS.OwnerUserId
), 
RecentActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Users U
    JOIN Posts P ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    UA.DisplayName,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalViews,
    UA.AverageScore,
    UA.LastAccessDate,
    UA.ReputationRank,
    RA.RecentPostRank
FROM UserActivity UA
LEFT JOIN RecentActivities RA ON UA.UserId = RA.UserId
WHERE UA.TotalQuestions > 0
ORDER BY UA.ReputationRank DESC, UA.TotalViews DESC;
