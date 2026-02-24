WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.PostId IS NOT NULL THEN 1 END) AS HistoryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.OwnerUserId, P.Score, P.ViewCount
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UV.UpVotes,
    UV.DownVotes,
    UV.TotalVotes,
    PS.PostId,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.HistoryCount
FROM Users U
LEFT JOIN UserVoteCounts UV ON U.Id = UV.UserId
LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
ORDER BY U.Reputation DESC, PS.Score DESC;