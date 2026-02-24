WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalPostScore,
        SUM(P.ViewCount) AS TotalPostViews
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
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalPostScore,
        TotalPostViews,
        RANK() OVER (ORDER BY TotalPostScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPostViews DESC) AS ViewsRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalPostScore,
    TotalPostViews,
    ScoreRank,
    ViewsRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY 
    ScoreRank, ViewsRank;