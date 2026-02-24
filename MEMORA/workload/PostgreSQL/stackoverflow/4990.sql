
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalBounty DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    TU.DisplayName AS User,
    R.Title AS RecentPost,
    R.CreationDate AS PostDate,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalBounty
FROM 
    TopUsers TU
LEFT JOIN 
    RankedPosts R ON TU.UserId = R.PostId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.TotalPosts DESC, TU.TotalBounty DESC NULLS LAST;
