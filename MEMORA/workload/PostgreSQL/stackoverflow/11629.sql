WITH UserPostStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(Posts.Id) AS TotalPosts,
        COUNT(CASE WHEN Posts.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN Posts.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(Posts.Score) AS TotalScore,
        AVG(Posts.ViewCount) AS AvgViewCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.Reputation
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
        RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS UserRank
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
    UserRank
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;