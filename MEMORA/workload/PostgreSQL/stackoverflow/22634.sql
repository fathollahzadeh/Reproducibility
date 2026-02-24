
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        LastAccessDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
    WHERE 
        Reputation IS NOT NULL
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        LAST_VALUE(P.CreationDate) OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastPostDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '2 year'  
        AND P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.ViewCount
    HAVING 
        COUNT(DISTINCT C.Id) > 5  
),
ModeratedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId AS ModeratorId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
        AND PH.UserId IS NOT NULL
),
UserModeration AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT MP.PostId) AS ModeratedPostCount
    FROM 
        Users U
    LEFT JOIN 
        ModeratedPosts MP ON U.Id = MP.ModeratorId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT MP.PostId) > 2  
)
SELECT 
    UM.DisplayName AS ModeratorName,
    COUNT(DISTINCT TP.PostId) AS TotalTopPostsModerated,
    SUM(TP.Score) AS TotalScore,
    SUM(TP.ViewCount) AS TotalViewCount,
    SUM(TP.TotalBountyAmount) AS TotalBounty
FROM 
    UserModeration UM
JOIN 
    TopPosts TP ON UM.UserId = TP.OwnerUserId
JOIN 
    UserReputation UR ON UM.UserId = UR.Id
GROUP BY 
    UM.DisplayName
ORDER BY 
    TotalScore DESC, TotalTopPostsModerated DESC
LIMIT 10;
