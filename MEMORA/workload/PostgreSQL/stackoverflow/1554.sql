WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.Title, P.CreationDate
),
TopPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.CommentCount,
        PD.UpVotes,
        PD.DownVotes,
        UR.DisplayName,
        UR.Reputation,
        RANK() OVER (ORDER BY PD.UpVotes DESC) AS PostRank
    FROM PostDetails PD
    JOIN UserReputation UR ON PD.OwnerUserId = UR.UserId
    WHERE UR.Rank <= 50
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    COALESCE((SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = TP.PostId AND PH.PostHistoryTypeId IN (10, 11)), 0) AS CloseHistoryCount,
    CASE 
        WHEN TP.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN TP.UpVotes > TP.DownVotes THEN 'Net Positive'
        WHEN TP.UpVotes < TP.DownVotes THEN 'Net Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM TopPosts TP
WHERE TP.PostRank <= 20
ORDER BY TP.UpVotes DESC, TP.CommentCount DESC;
