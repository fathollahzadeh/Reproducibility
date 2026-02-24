
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(Posts.Score) AS TotalPostScore,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN Posts.ViewCount IS NOT NULL THEN Posts.ViewCount ELSE 0 END) AS TotalViewCount,
        AVG(Posts.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Badges.Id) AS TotalBadges
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        TotalPostScore,
        TotalQuestions,
        TotalAnswers,
        TotalViewCount,
        AvgViewCount,
        TotalComments,
        TotalBadges,
        RANK() OVER (ORDER BY TotalPostScore DESC) AS RankByScore
    FROM 
        UserStats
)
SELECT 
    UserId,
    TotalPosts,
    TotalPostScore,
    TotalQuestions,
    TotalAnswers,
    TotalViewCount,
    AvgViewCount,
    TotalComments,
    TotalBadges,
    RankByScore
FROM 
    TopUsers
WHERE 
    RankByScore <= 10
ORDER BY 
    RankByScore;
