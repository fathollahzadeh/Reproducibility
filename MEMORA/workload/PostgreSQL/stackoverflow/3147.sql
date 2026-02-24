
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        PP.DisplayName AS OwnerDisplayName,
        COALESCE(AVG(V.BountyAmount), 0) AS AverageBounty,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PV.PostId IS NOT NULL THEN 1 END) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users PP ON P.OwnerUserId = PP.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id AND V.VoteTypeId = 9 
    LEFT JOIN 
        Votes PV ON PV.PostId = P.Id 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PP.DisplayName
), 
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
), 
TopPosts AS (
    SELECT 
        PD.*,
        UR.ReputationRank
    FROM 
        PostDetails PD
    JOIN 
        UserReputation UR ON PD.OwnerDisplayName = UR.DisplayName
    WHERE 
        PD.Score > 10
        AND PD.ViewCount > 100
)

SELECT 
    TP.Title,
    TP.CreationDate,
    TP.AverageBounty,
    TP.CommentCount,
    TP.VoteCount,
    CP.ClosedDate,
    CP.CloseReason,
    TP.ReputationRank
FROM 
    TopPosts TP
LEFT JOIN 
    ClosedPosts CP ON TP.PostId = CP.PostId
ORDER BY 
    TP.ReputationRank, TP.Score DESC;
