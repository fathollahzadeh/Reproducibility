
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.TotalUpVotes - PS.TotalDownVotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, (PS.TotalUpVotes - PS.TotalDownVotes) DESC) AS Rank
    FROM PostStats PS
    WHERE PS.TotalComments > 10
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.UpVotes,
    UPS.DownVotes,
    UPS.TotalPosts,
    UPS.CommentCount,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.NetVotes
FROM UserVoteStats UPS
JOIN TopPosts TP ON UPS.UpVotes > 10 OR UPS.DownVotes > 5
WHERE TP.Rank <= 50
ORDER BY UPS.UpVotes DESC, TP.Score DESC;
