
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id, 
        ParentId, 
        Title, 
        OwnerUserId, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.ParentId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Location,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Location
),
PostActivity AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        PH.Level, 
        U.DisplayName AS OwnerDisplayName,
        COUNT(CM.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHierarchy PH ON PH.Id = P.Id
    GROUP BY 
        P.Id, P.Title, PH.Level, U.DisplayName
),
ActiveUserPosts AS (
    SELECT 
        PH.OwnerUserId, 
        COUNT(DISTINCT PA.PostId) AS ActivePosts, 
        SUM(PA.CommentCount) AS TotalComments, 
        SUM(PA.VoteCount) AS TotalVotes, 
        SUM(PA.TotalBounty) AS TotalBountyValue
    FROM 
        PostActivity PA
    JOIN 
        PostHierarchy PH ON PA.PostId = PH.Id
    GROUP BY 
        PH.OwnerUserId
),
FinalResult AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.BadgeCount, 
        COALESCE(AP.ActivePosts, 0) AS ActivePostCount,
        COALESCE(AP.TotalComments, 0) AS TotalComments,
        COALESCE(AP.TotalVotes, 0) AS TotalVotes,
        COALESCE(AP.TotalBountyValue, 0) AS TotalBountyValue
    FROM 
        UserScore U
    LEFT JOIN 
        ActiveUserPosts AP ON U.UserId = AP.OwnerUserId
)
SELECT 
    FR.UserId,
    FR.DisplayName,
    FR.Reputation,
    FR.BadgeCount,
    FR.ActivePostCount,
    FR.TotalComments,
    FR.TotalVotes,
    FR.TotalBountyValue,
    (FR.Reputation + FR.BadgeCount * 10 + FR.ActivePostCount * 5 + FR.TotalBountyValue) AS PerformanceScore
FROM 
    FinalResult FR
ORDER BY 
    PerformanceScore DESC
LIMIT 10;
