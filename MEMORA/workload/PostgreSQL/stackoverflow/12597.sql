
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(CA.Id, -1) AS AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Posts CA ON P.AcceptedAnswerId = CA.Id
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, CA.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AcceptedAnswerId,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    UV.TotalVotes,
    UV.TotalUpVotes,
    UV.TotalDownVotes
FROM PostStats PS
JOIN UserVotes UV ON PS.AcceptedAnswerId = UV.UserId
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
