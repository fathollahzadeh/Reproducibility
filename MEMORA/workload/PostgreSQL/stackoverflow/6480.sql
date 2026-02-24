WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, PostCount, QuestionCount, AnswerCount, TotalViews, TotalScore,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPosts
    WHERE 
        PostCount > 10
)
SELECT 
    TU.DisplayName, 
    TU.PostCount, 
    TU.QuestionCount, 
    TU.AnswerCount, 
    TU.TotalViews, 
    TU.TotalScore
FROM 
    TopUsers TU
WHERE 
    TU.ScoreRank <= 10
ORDER BY 
    TU.TotalScore DESC;
