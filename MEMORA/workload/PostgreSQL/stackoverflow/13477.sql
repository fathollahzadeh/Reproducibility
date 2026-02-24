WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostTypeStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViewCount
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Id, PT.Name
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalScore,
    UPS.AverageViewCount,
    PTS.PostTypeId,
    PTS.PostTypeName,
    PTS.PostCount,
    PTS.AverageScore,
    PTS.TotalViewCount
FROM 
    UserPostStats UPS
JOIN 
    PostTypeStats PTS ON UPS.UserId IS NOT NULL
ORDER BY 
    UPS.TotalPosts DESC, 
    PTS.PostCount DESC;