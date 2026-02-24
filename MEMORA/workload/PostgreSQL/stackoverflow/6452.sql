
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), PostTypesStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Name
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalComments,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        US.TotalUpvotes,
        US.TotalDownvotes,
        PTS.PostTypeName,
        PTS.PostCount
    FROM 
        UserStats US
    LEFT JOIN 
        BadgeCounts BC ON US.UserId = BC.UserId
    LEFT JOIN 
        PostTypesStats PTS ON US.TotalPosts > 0
) 
SELECT 
    *,
    (TotalUpvotes - TotalDownvotes) AS NetVotes,
    (TotalPosts + TotalComments + TotalBadges) AS EngagementScore
FROM 
    CombinedStats
ORDER BY 
    EngagementScore DESC;
