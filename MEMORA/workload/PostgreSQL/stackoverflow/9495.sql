
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        COUNT(DISTINCT B.Id) AS BadgesCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        US.Reputation, 
        US.UpVotes - US.DownVotes AS NetVotes,
        US.PostsCount, 
        US.CommentsCount, 
        US.BadgesCount
    FROM Users U
    JOIN UserStats US ON U.Id = US.UserId
    WHERE U.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' AND US.PostsCount > 5
),
TopUsers AS (
    SELECT 
        A.DisplayName,
        A.Reputation,
        A.NetVotes,
        A.PostsCount,
        A.CommentsCount,
        A.BadgesCount,
        RANK() OVER (ORDER BY A.NetVotes DESC, A.Reputation DESC) AS Rank
    FROM ActiveUsers A
)
SELECT * 
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
