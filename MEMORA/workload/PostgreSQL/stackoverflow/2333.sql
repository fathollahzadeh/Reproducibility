
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        RANK() OVER (ORDER BY U.Reputation DESC) as ReputationRank 
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBounty 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId IN (8, 9) 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
PostHistoryAggregate AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    UR.DisplayName,
    DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    PH.LastChangeDate,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    CASE 
        WHEN UR.Reputation < 100 THEN 'Low Reputation'
        WHEN UR.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        ELSE 'High Reputation' 
    END AS ReputationTier
FROM 
    PostDetails P
JOIN 
    UserReputation UR ON P.OwnerUserId = UR.UserId
LEFT JOIN 
    PostHistoryAggregate PH ON P.PostId = PH.PostId
LEFT JOIN 
    ClosedPosts CP ON P.PostId = CP.ClosedPostId 
WHERE 
    P.Score > 0 AND 
    P.ViewCount > 100 AND 
    UR.ReputationRank <= 100
ORDER BY 
    UR.Reputation DESC, 
    P.Score DESC;
