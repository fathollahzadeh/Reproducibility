
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year')
),
PostHistoryRecent AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    COALESCE(UVS.VoteCount, 0) AS UserVoteCount,
    COALESCE(UVS.UpVotes, 0) AS UserUpVotes,
    COALESCE(UVS.DownVotes, 0) AS UserDownVotes,
    COALESCE(PHR.EditCount, 0) AS PostEditCount,
    PHR.LastEditDate,
    CASE 
        WHEN PHR.LastEditDate IS NULL THEN 'Never Edited'
        ELSE 'Edited'
    END AS EditStatus
FROM RecentPosts RP
LEFT JOIN UserVoteStats UVS ON RP.OwnerDisplayName = CAST(UVS.UserId AS VARCHAR)
LEFT JOIN PostHistoryRecent PHR ON RP.PostId = PHR.PostId
WHERE RP.Rank = 1
ORDER BY RP.Score DESC, RP.ViewCount DESC 
LIMIT 50;
