
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(B.Class) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUserStats AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalScore,
        TotalBadges,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserStats
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    R.ReputationRank,
    R.ScoreRank,
    R.PostRank
FROM RankedUserStats R
JOIN Users U ON R.UserId = U.Id
WHERE R.ReputationRank <= 10 OR R.ScoreRank <= 10 OR R.PostRank <= 10
ORDER BY R.ReputationRank, R.ScoreRank, R.PostRank;
