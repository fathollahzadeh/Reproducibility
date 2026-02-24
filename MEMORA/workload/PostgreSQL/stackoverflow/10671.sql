WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        AVG(U.Reputation) AS AvgReputation,
        SUM(U.Views) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    AvgReputation,
    TotalViews,
    PostCount,
    BadgeCount
FROM 
    UserStatistics
ORDER BY 
    AvgReputation DESC;