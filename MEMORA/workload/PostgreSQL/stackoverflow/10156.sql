WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.AnswerCount) AS AvgAnswerCount,
        AVG(P.CommentCount) AS AvgCommentCount,
        AVG(P.FavoriteCount) AS AvgFavoriteCount
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
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        AvgAnswerCount,
        AvgCommentCount,
        AvgFavoriteCount,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    AvgViewCount,
    AvgAnswerCount,
    AvgCommentCount,
    AvgFavoriteCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;