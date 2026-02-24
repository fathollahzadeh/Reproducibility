WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPerformance AS (
    SELECT
        UR.DisplayName,
        UR.Reputation,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalScore,
        PS.TotalViews,
        COALESCE(PS.QuestionCount * 3 + PS.AnswerCount * 2 + PS.TotalScore, 0) AS PerformanceScore
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PerformanceScore DESC) AS ScoreRank
    FROM UserPerformance
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.TotalViews,
    U.PerformanceScore,
    CASE 
        WHEN U.ScoreRank <= 10 THEN 'Top Performer'
        ELSE 'Regular User'
    END AS UserCategory
FROM TopUsers U
WHERE U.Reputation > 5000 
AND U.QuestionCount > 5
ORDER BY U.PerformanceScore DESC;