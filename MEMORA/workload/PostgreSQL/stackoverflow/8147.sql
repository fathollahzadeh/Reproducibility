WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes, 
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS Rank
    FROM UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.CommentCount
FROM MostActiveUsers U
WHERE U.Rank <= 10
ORDER BY U.Rank;
