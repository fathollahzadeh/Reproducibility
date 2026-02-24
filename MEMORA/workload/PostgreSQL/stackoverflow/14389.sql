WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS NumberOfPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        NumberOfPosts,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostCounts
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.NumberOfPosts,
    T.TotalViews,
    T.TotalScore
FROM 
    TopUsers T
WHERE 
    T.ScoreRank <= 10
ORDER BY 
    T.TotalScore DESC;