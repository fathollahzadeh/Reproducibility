
WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.CreationDate, P.OwnerUserId, P.AcceptedAnswerId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
ActivePostStats AS (
    SELECT
        PH.PostId,
        PH.Title,
        PH.CreationDate,
        PH.TotalBounty,
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        PH.CommentCount,
        PH.PostRank
    FROM 
        RecursivePostHierarchy PH
    JOIN 
        UserReputation U ON PH.OwnerUserId = U.UserId
)
SELECT 
    A.DisplayName,
    SUM(A.TotalBounty) AS TotalBountyEarned,
    COUNT(A.PostId) AS TotalPosts,
    AVG(A.Reputation) AS AvgReputation,
    SUM(A.CommentCount) AS TotalComments,
    STRING_AGG(A.Title, ', ') AS PostTitles,
    MAX(A.PostRank) AS HighestPostRank
FROM 
    ActivePostStats A
WHERE 
    A.CommentCount > 0
GROUP BY 
    A.DisplayName
HAVING 
    COUNT(A.PostId) > 5
ORDER BY 
    TotalPosts DESC, TotalBountyEarned DESC;
