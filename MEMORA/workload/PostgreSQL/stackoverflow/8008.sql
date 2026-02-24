WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
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
        TotalBounties, 
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserActivity
)
SELECT 
    TU.DisplayName,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBounties,
    TU.TotalComments,
    PT.Name AS PostTypeName,
    (SELECT 
         COUNT(*) 
     FROM 
         Posts P1 
     WHERE 
         P1.OwnerUserId = TU.UserId 
         AND P1.PostTypeId = PT.Id) AS PostCountByType
FROM 
    TopUsers TU
CROSS JOIN 
    PostTypes PT
WHERE 
    TU.PostRank <= 10
ORDER BY 
    TU.PostRank, PT.Id;