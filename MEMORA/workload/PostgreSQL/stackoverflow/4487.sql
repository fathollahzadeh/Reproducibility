
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(MAX(P.CreationDate), '1970-01-01'::date) AS LastPostDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY UA.LastPostDate DESC) AS ActivityRank
    FROM UserActivity UA
    WHERE UA.TotalPosts > 0
),
TopUsers AS (
    SELECT * 
    FROM RecentActivity
    WHERE ReputationRank <= 10 OR ActivityRank <= 10
),
BadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.ReputationRank,
    TU.ActivityRank,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN TU.ActivityRank <= 10 THEN 'Highly Active'
        WHEN TU.ReputationRank <= 10 THEN 'Highly Reputable'
        ELSE 'Regular User'
    END AS UserCategory
FROM TopUsers TU
LEFT JOIN BadgeCounts BC ON TU.UserId = BC.UserId
ORDER BY TU.Reputation DESC, TU.ActivityRank ASC
LIMIT 20;
