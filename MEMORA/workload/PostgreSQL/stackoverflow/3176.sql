WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.Reputation, U.DisplayName
),
TopBadges AS (
    SELECT
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM
        Badges B
    GROUP BY
        B.UserId
    HAVING
        COUNT(B.Id) > 1
),
RecentPostStats AS (
    SELECT
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM
        Posts P
    WHERE
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT
    U.DisplayName,
    COALESCE(UR.Reputation, 0) AS Reputation,
    COALESCE(UR.PostCount, 0) AS TotalPosts,
    COALESCE(UR.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UR.DownVotes, 0) AS TotalDownVotes,
    COALESCE(TB.BadgeCount, 0) AS TotalBadges,
    COALESCE(TB.BadgeNames, 'None') AS Badges,
    RP.Title AS RecentPostTitle,
    RP.ViewCount AS RecentPostViewCount
FROM
    Users U
LEFT JOIN
    UserReputation UR ON U.Id = UR.UserId
LEFT JOIN
    TopBadges TB ON U.Id = TB.UserId
LEFT JOIN
    RecentPostStats RP ON U.Id = RP.OwnerUserId AND RP.PostRank = 1
WHERE
    U.Reputation > 1000
ORDER BY
    UR.Reputation DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;