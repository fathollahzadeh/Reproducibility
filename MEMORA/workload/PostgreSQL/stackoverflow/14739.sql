
WITH PostStatistics AS (
    SELECT
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY PT.Name
),

UserStatistics AS (
    SELECT
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS UserPostCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Reputation
)

SELECT
    PS.PostType,
    PS.PostCount,
    PS.UpVotes,
    PS.DownVotes,
    US.Reputation,
    US.BadgeCount,
    US.UserPostCount
FROM PostStatistics PS
JOIN UserStatistics US ON US.UserPostCount > 0
ORDER BY PS.PostType, US.Reputation;
