WITH UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MIN(P.CreationDate) AS EarliestPost,
        MAX(P.CreationDate) AS LatestPost
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    U.TotalAnswers,
    U.TotalComments,
    PS.PostType,
    PS.PostCount,
    PS.TotalViews,
    PS.AverageScore,
    PS.EarliestPost,
    PS.LatestPost
FROM 
    UserPostMetrics U
LEFT JOIN 
    PostStatistics PS ON PS.PostType IN ('Question', 'Answer')
ORDER BY 
    U.TotalScore DESC, U.TotalPosts DESC;