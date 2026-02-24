WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostInteraction AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalPostScore,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.CreationDate,
        US.BadgeCount,
        US.TotalUpvotes,
        US.TotalDownvotes,
        PI.PostCount,
        COALESCE(PI.TotalPostScore, 0) AS TotalPostScore,
        COALESCE(PI.TotalViews, 0) AS TotalViews,
        PI.LastPostDate
    FROM 
        UserStats US
    LEFT JOIN 
        PostInteraction PI ON US.UserId = PI.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    BadgeCount,
    TotalUpvotes,
    TotalDownvotes,
    PostCount,
    TotalPostScore,
    TotalViews,
    LastPostDate
FROM 
    UserPerformance
WHERE 
    Reputation > 1000
ORDER BY 
    Reputation DESC, TotalPostScore DESC;
