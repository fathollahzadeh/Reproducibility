WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(B.Class) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBounty,
        MAX(U.Reputation) AS MaxReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(C.Id) AS TotalComments,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
),
UserPostInfo AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalBadges,
        U.TotalBounty,
        U.MaxReputation,
        COALESCE(S.TotalPosts, 0) AS TotalPosts,
        COALESCE(S.TotalViews, 0) AS TotalViews,
        COALESCE(S.TotalComments, 0) AS TotalComments,
        COALESCE(S.AvgScore, 0) AS AvgScore,
        S.LastPostDate
    FROM 
        UserReputation U
    LEFT JOIN 
        PostStatistics S ON U.UserId = S.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalBounty,
    MaxReputation,
    TotalPosts,
    TotalViews,
    TotalComments,
    AvgScore,
    LastPostDate,
    RANK() OVER (ORDER BY TotalReputation DESC) AS ReputationRank
FROM (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        TotalBounty,
        MaxReputation,
        TotalPosts,
        TotalViews,
        TotalComments,
        AvgScore,
        LastPostDate,
        (MaxReputation + TotalBounty + TotalBadges * 10) AS TotalReputation
    FROM 
        UserPostInfo
) AS RankedUsers
ORDER BY 
    TotalReputation DESC
LIMIT 10;
