
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBountyEarned
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE
        U.Reputation > 1000
    GROUP BY
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM
        Posts P
    WHERE
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalBadges,
    UA.TotalBountyEarned,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount
FROM
    UserActivity UA
JOIN PostStatistics PS ON UA.UserId = PS.PostId
ORDER BY
    UA.TotalBountyEarned DESC, 
    PS.Score DESC 
LIMIT 50;
