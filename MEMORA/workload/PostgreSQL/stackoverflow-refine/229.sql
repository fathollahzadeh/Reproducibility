WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS UserRank
    FROM Posts P
    WHERE P.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS TopBadgeClass
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalViews,
    UA.TotalScore,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    COALESCE(UP.BadgeCount, 0) AS BadgeCount,
    COALESCE(UP.TopBadgeClass, 0) AS TopBadgeClass,
    PP.Title,
    PP.CreationDate,
    PP.ViewCount,
    PP.Score
FROM UserActivity UA
LEFT JOIN UsersWithBadges UP ON UA.UserId = UP.UserId
LEFT JOIN PopularPosts PP ON UA.UserId = PP.OwnerUserId AND PP.UserRank <= 3
WHERE UA.Reputation > 100
ORDER BY UA.Reputation DESC, PP.Score DESC NULLS LAST
LIMIT 50;