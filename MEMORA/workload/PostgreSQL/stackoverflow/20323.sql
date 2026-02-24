WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RecentView,
        LAG(U.Reputation, 1, 0) OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS PreviousReputation
    FROM 
        Users U
    WHERE 
        U.Reputation > 100
), 
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
PostHistoryDetails AS (
    SELECT 
        H.PostId,
        H.UserId,
        PH.Name AS HistoryType,
        COUNT(*) AS RevisionCount,
        MAX(H.CreationDate) AS LastRevisionDate
    FROM 
        PostHistory H
    JOIN 
        PostHistoryTypes PH ON H.PostHistoryTypeId = PH.Id
    GROUP BY 
        H.PostId, H.UserId, PH.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.LastAccessDate,
    S.PostId,
    S.Title as PostTitle,
    S.CommentCount,
    S.UpVotes,
    S.DownVotes,
    COALESCE(PH.HistoryType, 'No Modifications') AS LastHistoryType,
    PH.RevisionCount,
    PH.LastRevisionDate,
    CASE 
        WHEN (U.Reputation - U.PreviousReputation) > 0 THEN 'Increased'
        WHEN (U.Reputation - U.PreviousReputation) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END as ReputationChange
FROM 
    UserReputation U
LEFT JOIN 
    ActivePosts S ON U.UserId = S.OwnerUserId
LEFT JOIN 
    PostHistoryDetails PH ON S.PostId = PH.PostId
WHERE 
    (PH.RevisionCount > 5 OR S.CommentCount > 0)
ORDER BY 
    U.Reputation DESC, S.CreationDate DESC
LIMIT 100;