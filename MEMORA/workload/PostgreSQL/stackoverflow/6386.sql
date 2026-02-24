
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        U.UpVoteCount,
        U.DownVoteCount,
        P.PostCount,
        P.TotalScore,
        P.CommentCount
    FROM UserStats U
    LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
)
SELECT 
    CS.DisplayName,
    CS.Reputation,
    CS.BadgeCount,
    CS.UpVoteCount,
    CS.DownVoteCount,
    COALESCE(CS.PostCount, 0) AS PostCount,
    COALESCE(CS.TotalScore, 0) AS TotalScore,
    COALESCE(CS.CommentCount, 0) AS CommentCount
FROM CombinedStats CS
WHERE CS.Reputation > 100 
ORDER BY CS.Reputation DESC, CS.BadgeCount DESC
LIMIT 10;
