
WITH UserPostStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore,
        AVG(Posts.Score) AS AvgPostScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostActivityStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        Posts.Score,
        Posts.AnswerCount,
        Posts.CommentCount,
        COALESCE(Users.DisplayName, 'Community') AS OwnerDisplayName,
        Posts.OwnerUserId
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalScore,
        AvgPostScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        UserPostStats
)

SELECT 
    TopUsers.UserId,
    TopUsers.DisplayName,
    TopUsers.TotalPosts,
    TopUsers.TotalQuestions,
    TopUsers.TotalAnswers,
    TopUsers.TotalViews,
    TopUsers.TotalScore,
    TopUsers.AvgPostScore,
    PostActivityStats.PostId,
    PostActivityStats.Title,
    PostActivityStats.CreationDate,
    PostActivityStats.ViewCount,
    PostActivityStats.Score,
    PostActivityStats.AnswerCount,
    PostActivityStats.CommentCount,
    PostActivityStats.OwnerDisplayName
FROM 
    TopUsers
LEFT JOIN 
    PostActivityStats ON TopUsers.UserId = PostActivityStats.OwnerUserId
WHERE 
    TopUsers.Rank <= 10  
ORDER BY 
    TopUsers.TotalViews DESC, PostActivityStats.ViewCount DESC;
