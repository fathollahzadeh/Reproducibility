
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
), PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE P.CreationDate > DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY T.TagName
    HAVING COUNT(DISTINCT P.Id) > 50
), ActiveUsers AS (
    SELECT 
        U.DisplayName, 
        U.Id,
        US.Reputation,
        US.BadgeCount,
        US.UpVotes,
        US.DownVotes,
        US.PostCount,
        US.CommentCount,
        US.LastPostDate
    FROM UserStats US
    JOIN Users U ON US.UserId = U.Id
    WHERE US.PostCount > 5 AND US.CommentCount > 10
)
SELECT 
    AU.DisplayName, 
    AU.Reputation, 
    AU.BadgeCount, 
    AU.UpVotes, 
    AU.DownVotes,
    PT.TagName,
    PT.PostCount
FROM ActiveUsers AU
JOIN PopularTags PT ON AU.PostCount > PT.PostCount
ORDER BY AU.Reputation DESC, PT.PostCount DESC
FETCH FIRST 10 ROWS ONLY;
