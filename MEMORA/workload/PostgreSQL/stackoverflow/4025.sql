
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
CloseReasonSummary AS (
    SELECT
        PH.PostId,
        COUNT(*) AS CloseReasonCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
)
SELECT
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostsCount,
    UA.CommentsCount,
    UA.TotalVotes,
    UA.UserRank,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS RecentPostDate,
    RP.Score,
    RP.ViewCount,
    CR.CloseReasonCount
FROM UserActivity UA
LEFT JOIN RecentPosts RP ON UA.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN CloseReasonSummary CR ON RP.PostId = CR.PostId
WHERE UA.Reputation > 1000
  AND (RP.Score IS NOT NULL OR RP.ViewCount > 100)
ORDER BY UA.UserRank;
