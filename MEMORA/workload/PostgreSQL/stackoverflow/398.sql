WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
), TopPosts AS (
    SELECT 
        RP.*,
        UR.ReputationRank
    FROM RecentPosts RP
    JOIN UserReputation UR ON RP.OwnerDisplayName = UR.DisplayName
    WHERE RP.PostRank = 1
), VotesSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
), FinalSummary AS (
    SELECT 
        TP.*, 
        VS.UpVotes, 
        VS.DownVotes,
        (TP.Score + COALESCE(VS.UpVotes, 0) - COALESCE(VS.DownVotes, 0)) AS NetScore
    FROM TopPosts TP
    LEFT JOIN VotesSummary VS ON TP.PostId = VS.PostId
)
SELECT 
    FS.OwnerDisplayName,
    FS.Title,
    FS.CreationDate,
    FS.ViewCount,
    FS.Score,
    FS.UpVotes,
    FS.DownVotes,
    FS.NetScore,
    FS.ReputationRank
FROM FinalSummary FS
WHERE FS.ReputationRank <= 10
ORDER BY FS.NetScore DESC, FS.ViewCount DESC
LIMIT 10;