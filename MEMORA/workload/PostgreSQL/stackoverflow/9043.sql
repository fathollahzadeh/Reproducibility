
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
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
        RANK() OVER (ORDER BY TotalPosts DESC, TotalBounties DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalQuestions, 
    U.TotalAnswers, 
    U.TotalBounties, 
    U.TotalComments
FROM TopUsers U
WHERE U.UserRank <= 10
ORDER BY U.TotalPosts DESC, U.TotalBounties DESC;
