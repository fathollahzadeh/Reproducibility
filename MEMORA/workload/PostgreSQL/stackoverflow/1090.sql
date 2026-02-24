
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.UpVotes,
        UA.DownVotes,
        UA.CommentCount
    FROM UserActivity UA
    WHERE UA.PostRank <= 10
),
PostWithVotes AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
PostStatistics AS (
    SELECT 
        PW.PostId,
        PW.Title,
        PW.Score,
        PW.ViewCount,
        PW.CreationDate,
        COALESCE(PW.UpVoteCount, 0) AS TotalUpVotes,
        COALESCE(PW.DownVoteCount, 0) AS TotalDownVotes,
        CASE 
            WHEN PW.Score IS NULL THEN 'No Score'
            WHEN PW.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreCategory
    FROM PostWithVotes PW
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.UpVotes,
    TU.DownVotes,
    TU.CommentCount,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CreationDate,
    PS.ScoreCategory
FROM TopUsers TU
JOIN PostStatistics PS ON TU.UserId = PS.PostId
WHERE PS.TotalUpVotes > 5
ORDER BY TU.UpVotes DESC, PS.CreationDate DESC;
