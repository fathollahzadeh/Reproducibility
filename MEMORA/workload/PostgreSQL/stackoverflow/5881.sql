WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalClosedPosts,
        TotalBountyAmount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers,
    T.TotalClosedPosts,
    T.TotalBountyAmount
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.TotalPosts DESC;
