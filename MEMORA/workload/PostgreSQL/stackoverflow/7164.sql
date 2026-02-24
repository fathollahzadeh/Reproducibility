WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBounties
    FROM 
        TopUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    AU.DisplayName,
    AU.Reputation,
    AU.TotalPosts,
    AU.TotalQuestions,
    AU.TotalAnswers,
    AU.TotalComments,
    AU.TotalBounties,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    ActiveUsers AU
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) B ON AU.UserId = B.UserId
ORDER BY 
    AU.Reputation DESC;
