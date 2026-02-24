WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        PostCount,
        TotalScore,
        TotalCommentScore,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS RankByTotalScore
    FROM 
        UserStats
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    A.PostCount,
    A.TotalScore,
    A.TotalCommentScore,
    A.RankByPostCount,
    A.RankByTotalScore
FROM 
    Users U
JOIN 
    MostActiveUsers A ON U.Id = A.UserId
WHERE 
    A.RankByPostCount <= 10 OR A.RankByTotalScore <= 10
ORDER BY 
    A.RankByPostCount, A.RankByTotalScore;