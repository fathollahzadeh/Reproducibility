
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.TotalUpVotes - PS.TotalDownVotes AS NetScore,
        RANK() OVER (ORDER BY PS.TotalUpVotes DESC, PS.CommentCount DESC) AS Rank
    FROM PostStatistics PS
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    TP.PostId,
    TP.Title,
    TP.NetScore,
    UP.TotalVotes AS UserTotalVotes,
    UP.UpVotesCount,
    UP.DownVotesCount
FROM UserVoteCounts UP
JOIN TopPosts TP ON UP.TotalVotes > 0 
WHERE TP.Rank <= 10
ORDER BY TP.NetScore DESC, UP.TotalVotes DESC;
