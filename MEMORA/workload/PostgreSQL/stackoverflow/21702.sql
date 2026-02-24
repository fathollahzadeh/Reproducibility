WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        CTE.ReputationRank,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    JOIN UserReputation CTE ON P.OwnerUserId = CTE.UserId
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId, CTE.ReputationRank
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank,
        PH.Comment
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15, 20)
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation,
    CASE 
        WHEN RP.ReputationRank <= 10 THEN 'Top Reputation User'
        ELSE 'Regular User'
    END AS UserCategory,
    COALESCE(PHD.Comment, 'No history') AS RecentActivity,
    CASE 
        WHEN PHD.HistoryRank = 1 THEN 'Most Recent Change'
        ELSE 'Earlier Change'
    END AS ChangeCategory
FROM RecentPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
LEFT JOIN PostHistoryDetails PHD ON RP.PostId = PHD.PostId AND PHD.HistoryRank = 1
WHERE RP.CommentCount > 0
ORDER BY RP.CreationDate DESC, RP.UpVotes DESC
LIMIT 50;