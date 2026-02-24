
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswer,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        P.ViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate, P.AcceptedAnswerId, P.Score, P.ViewCount
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3) AS DownVotes,
        RP.OwnerUserId
    FROM 
        RecentPosts RP
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    (CASE 
        WHEN PS.Score > 0 THEN 'Positive'
        WHEN PS.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END) AS PostSentiment
FROM 
    UserReputation UR
JOIN 
    PostStatistics PS ON UR.UserId = PS.OwnerUserId
WHERE 
    UR.ReputationRank <= 10
    AND (PS.CommentCount > 5 OR PS.ViewCount > 50)
ORDER BY 
    UR.Reputation DESC, PS.CreationDate DESC;
