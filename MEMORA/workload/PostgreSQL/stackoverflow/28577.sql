WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.BadgeCount,
        P.TotalPosts,
        P.TotalQuestions,
        P.TotalAnswers,
        P.TotalViews,
        RANK() OVER (ORDER BY U.BadgeCount DESC) AS BadgeRank,
        RANK() OVER (ORDER BY P.TotalPosts DESC) AS PostRank
    FROM 
        UserBadgeCounts U
    JOIN 
        PostStatistics P ON U.UserId = P.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    BadgeRank,
    PostRank
FROM 
    TopUsers
WHERE 
    BadgeRank <= 10 OR PostRank <= 10
ORDER BY 
    BadgeRank, PostRank;
