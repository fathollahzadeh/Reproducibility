WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(C.Id) AS NumberOfComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
),
UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(PS.TotalUpvotes) AS TotalUpvotes,
        SUM(PS.TotalDownvotes) AS TotalDownvotes,
        SUM(PS.TotalBounty) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostStatistics PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    RU.UserRank,
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalUpvotes,
    UPS.TotalDownvotes,
    UPS.TotalBounty
FROM 
    RankedUsers RU
JOIN 
    UserPostStats UPS ON RU.UserId = UPS.UserId
WHERE 
    RU.UserRank <= 10
ORDER BY 
    RU.UserRank;
