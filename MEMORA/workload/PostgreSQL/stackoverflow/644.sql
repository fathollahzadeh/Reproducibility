
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
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
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        U.DisplayName AS OwnerDisplayName,
        UVC.TotalVotes,
        UVC.UpVotes,
        UVC.DownVotes,
        RP.CommentCount,
        COALESCE((SELECT COUNT(1) FROM PostLinks PL WHERE PL.PostId = RP.PostId), 0) AS RelatedPostCount
    FROM RecentPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN UserVoteCounts UVC ON U.Id = UVC.UserId
    WHERE RP.RN = 1
)
SELECT 
    PS.Title,
    PS.OwnerDisplayName,
    PS.TotalVotes,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.RelatedPostCount,
    CASE 
        WHEN PS.TotalVotes > 0 THEN (CAST(PS.UpVotes AS DECIMAL) / PS.TotalVotes) * 100
        ELSE 0 
    END AS UpVotePercentage
FROM PostStatistics PS
WHERE PS.CommentCount > 5
ORDER BY UpVotePercentage DESC
LIMIT 10;
