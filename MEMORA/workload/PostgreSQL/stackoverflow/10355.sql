WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS PostsCreated,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN P.Id END) AS AcceptedAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounty,
    PS.PostsCreated,
    PS.TotalViews,
    PS.AverageScore,
    PS.AcceptedAnswers
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY 
    US.TotalPosts DESC, US.Reputation DESC;