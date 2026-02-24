
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePostCount,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativePostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank,
        P.OwnerUserId
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
)
SELECT 
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.PositivePostCount,
    US.NegativePostCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount
FROM UserStats US
LEFT JOIN TopPosts TP ON US.UserId = TP.OwnerUserId
WHERE TP.Rank <= 10
ORDER BY US.Reputation DESC, TP.Score DESC;
