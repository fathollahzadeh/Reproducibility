WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.AnswerCount, 0)) AS AvgAnswers,
        AVG(COALESCE(P.CommentCount, 0)) AS AvgComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalScore,
        TotalViews,
        AvgAnswers,
        AvgComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    TU.PostCount,
    TU.TotalScore,
    TU.TotalViews,
    TU.AvgAnswers,
    TU.AvgComments
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
WHERE 
    TU.ScoreRank <= 10
ORDER BY 
    TU.ScoreRank;