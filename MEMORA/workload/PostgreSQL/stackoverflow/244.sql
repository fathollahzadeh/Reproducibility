WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.AverageScore,
        UA.TotalViews,
        R.ReputationRank
    FROM UserActivity UA
    JOIN UserReputation R ON UA.UserId = R.UserId
    WHERE UA.TotalPosts > 0
)
SELECT 
    U.*,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     JOIN Tags T ON P.Tags ILIKE '%' || T.TagName || '%' 
     WHERE P.OwnerUserId = U.UserId) AS TagsUsed,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.UserId = U.UserId) AS TotalComments,
    (SELECT COUNT(*) 
     FROM Badges B 
     WHERE B.UserId = U.UserId) AS TotalBadges
FROM TopUsers U
WHERE U.ReputationRank <= 10
ORDER BY U.TotalViews DESC, U.AverageScore DESC
LIMIT 5;
