WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        TotalViews,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, BadgeCount DESC, TotalViews DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.BadgeCount,
    T.TotalViews,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank;
