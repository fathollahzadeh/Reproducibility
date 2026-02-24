
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount
    FROM UserActivity
    WHERE PostRank <= 50
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.CommentCount,
    TU.UpVotes,
    TU.DownVotes,
    TU.BadgeCount,
    ROUND((CAST(TU.UpVotes AS DECIMAL) / NULLIF(TU.PostCount, 0)) * 100, 2) AS UpvotePercentage,
    ROUND((CAST(TU.DownVotes AS DECIMAL) / NULLIF(TU.PostCount, 0)) * 100, 2) AS DownvotePercentage
FROM TopUsers TU
ORDER BY TU.PostCount DESC, TU.UpVotes DESC;
