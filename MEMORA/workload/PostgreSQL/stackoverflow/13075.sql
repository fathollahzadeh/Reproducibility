WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostTypesStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Name
)

SELECT 
    UStats.UserId,
    UStats.DisplayName,
    UStats.TotalPosts,
    UStats.Questions,
    UStats.Answers,
    UStats.Wikis,
    UStats.TotalScore,
    UStats.TotalViews,
    PTStats.PostTypeName,
    PTStats.PostCount,
    PTStats.TotalScore AS PostTypeTotalScore,
    PTStats.AverageViewCount
FROM 
    UserStatistics UStats
JOIN 
    PostTypesStats PTStats ON UStats.TotalPosts > 0
ORDER BY 
    UStats.TotalScore DESC, 
    PTStats.PostTypeName;