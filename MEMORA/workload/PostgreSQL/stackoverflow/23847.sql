WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(
            CASE
                WHEN V.VoteTypeId = 2 THEN 1
                ELSE 0
            END
        ) AS TotalUpVotes,
        SUM(
            CASE
                WHEN V.VoteTypeId = 3 THEN 1
                ELSE 0
            END
        ) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.LastAccessDate DESC) AS UserRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.LastAccessDate
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT
        US.UserId,
        US.Reputation,
        US.TotalBadges,
        US.TotalUpVotes,
        US.TotalDownVotes,
        RANK() OVER (ORDER BY US.Reputation DESC) AS ReputationRank
    FROM UserStats US
    WHERE US.TotalBadges > 5 
)

SELECT
    TU.UserId,
    TU.Reputation,
    TU.TotalBadges,
    P.Title AS RecentPostTitle,
    P.CreationDate AS RecentPostDate,
    COALESCE(P.Score, 0) AS PostScore,
    COALESCE(P.ViewCount, 0) AS PostViewCount,
    (SELECT COUNT(Comment.Id) FROM Comments Comment WHERE Comment.PostId = P.PostId) AS TotalComments,
    CASE WHEN P.CreationDate IS NOT NULL THEN
        CASE 
            WHEN P.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '14 days' THEN 'Old Post'
            WHEN P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 days' THEN 'New Post'
            ELSE 'Somewhat Recent Post'
        END
    ELSE 'No Recent Posts'
    END AS PostAgeCategory
FROM TopUsers TU
LEFT JOIN RecentPosts P ON TU.UserId = P.OwnerUserId AND P.RecentPostRank = 1 
WHERE TU.ReputationRank <= 10 
ORDER BY TU.Reputation DESC, RecentPostDate DESC;