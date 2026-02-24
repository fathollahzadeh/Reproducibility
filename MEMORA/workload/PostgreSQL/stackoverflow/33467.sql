
WITH RECURSIVE UserPostCount AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions, 
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostCount
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        P.Title,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Location,
    U.CreationDate,
    COALESCE(TAU.TotalPosts, 0) AS TotalPosts,
    COALESCE(TAU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TAU.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(TAU.TotalViews, 0) AS TotalViews,
    STRING_AGG(RPH.Comment, '; ') AS RecentComments,
    STRING_AGG(RPH.Title, ', ') AS RecentPostsTitles
FROM 
    Users U 
LEFT JOIN 
    TopActiveUsers TAU ON U.Id = TAU.UserId
LEFT JOIN 
    RecentPostHistory RPH ON U.Id = RPH.UserId AND RPH.rn = 1
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.Location, U.CreationDate, TAU.TotalPosts, TAU.TotalAnswers, TAU.TotalQuestions, TAU.TotalViews
HAVING 
    COALESCE(TAU.TotalPosts, 0) > 5
ORDER BY 
    TAU.TotalPosts DESC;
