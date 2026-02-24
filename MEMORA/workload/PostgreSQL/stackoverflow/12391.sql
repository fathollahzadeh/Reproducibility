WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
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
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AverageViews,
        AVG(P.Score) AS AverageScore
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
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalViews,
    U.AverageScore,
    PS.PostType,
    PS.TotalPosts,
    PS.AverageViews,
    PS.AverageScore
FROM 
    UserPostStats U
JOIN 
    PostStatistics PS ON U.PostCount > 0
ORDER BY 
    U.TotalViews DESC, U.AverageScore DESC;