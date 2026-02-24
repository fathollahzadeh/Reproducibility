
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId, P.PostTypeId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PT.Name AS PostTypeName
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PHT.Name = 'Post Closed'
)
SELECT 
    U.DisplayName, 
    U.Reputation,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    CP.UserDisplayName AS ClosedBy,
    CP.CreationDate AS ClosedDate,
    CASE 
        WHEN RP.LastVoteDate IS NULL THEN 'No Votes'
        ELSE 'Voted'
    END AS VoteStatus
FROM 
    UserReputation U
JOIN 
    RecentPosts RP ON U.UserId = RP.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    U.Reputation DESC, RP.Score DESC
FETCH FIRST 100 ROWS ONLY;
