
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount,
        U.Reputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 100 AND U.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.GoldBadgeCount,
    UA.SilverBadgeCount,
    UA.BronzeBadgeCount,
    PS.TotalPosts,
    PS.AverageScore,
    PS.TotalViews,
    PS.CommentCount
FROM UserActivity UA
JOIN PostStatistics PS ON UA.UserId = PS.OwnerUserId
ORDER BY UA.Reputation DESC, UA.PostCount DESC
LIMIT 50;
