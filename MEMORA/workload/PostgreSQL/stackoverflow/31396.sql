
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        UR.UserId,
        UR.Reputation + U.Reputation,
        Level + 1
    FROM 
        UserReputationCTE UR
    JOIN 
        Users U ON UR.UserId = U.Id
    WHERE 
        UR.Reputation + U.Reputation < 5000
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.Tags,
        P.Score,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 YEAR') 
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.Body, P.CreationDate, P.AcceptedAnswerId, P.Tags, P.Score
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate > (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 DAY')
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    PD.PostId,
    PD.Title,
    PD.Score,
    PD.UpVotes,
    PD.DownVotes,
    PD.CommentCount,
    PD.Rank,
    K.CreationDate AS LastPostDate,
    PH.UserDisplayName AS LastEditor
FROM 
    Users U
JOIN 
    UserReputationCTE UR ON U.Id = UR.UserId
JOIN 
    PostDetails PD ON U.DisplayName = PD.OwnerDisplayName 
LEFT JOIN 
    (SELECT DISTINCT PH.PostId, PH.CreationDate 
     FROM PostHistory PH 
     ORDER BY PH.PostId, PH.CreationDate DESC) K ON PD.PostId = K.PostId
LEFT JOIN 
    RecentPostHistory PH ON PD.PostId = PH.PostId AND PH.rn = 1
WHERE 
    UR.Reputation BETWEEN 1000 AND 5000
ORDER BY 
    UR.Reputation DESC, PD.Score DESC;
