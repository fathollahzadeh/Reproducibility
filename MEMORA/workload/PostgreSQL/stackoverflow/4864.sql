WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        OffensiveVotes,
        PostsCount,
        ReputationRank
    FROM UserStats
    WHERE PostsCount > 0
    ORDER BY Reputation DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.UpVotes,
    TU.DownVotes,
    TU.OffensiveVotes,
    TU.PostsCount,
    UB.BadgeNames,
    UB.BadgeCount
FROM TopUsers TU
LEFT JOIN UserBadges UB ON TU.UserId = UB.UserId
WHERE TU.Reputation > 1000 OR UB.BadgeCount > 0
ORDER BY TU.Reputation DESC, UB.BadgeCount DESC;
