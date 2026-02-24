WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
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
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.TotalScore,
    CASE 
        WHEN T.ScoreRank <= 10 THEN 'Top Contributor'
        WHEN T.ScoreRank <= 50 THEN 'Contributor'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopUsers T
WHERE 
    T.TotalPosts > 50
ORDER BY 
    T.TotalScore DESC, T.TotalPosts DESC;
