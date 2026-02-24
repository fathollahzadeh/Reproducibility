WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
           COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT UserId, Reputation, TotalViews, BadgeCount,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           RANK() OVER (ORDER BY TotalViews DESC) AS ViewsRank
    FROM UserReputation
),
CombinedRanks AS (
    SELECT UserId, Reputation, TotalViews, BadgeCount, 
           COALESCE(ReputationRank, 999) AS ReputationRank,
           COALESCE(ViewsRank, 999) AS ViewsRank
    FROM TopUsers
)
SELECT U.DisplayName, 
       R.Reputation, 
       R.TotalViews,
       R.BadgeCount,
       (CASE 
            WHEN R.ReputationRank = 1 THEN 'Top Reputation'
            WHEN R.ViewsRank = 1 THEN 'Top Views'
            ELSE 'Regular User' 
        END) AS UserCategory,
       COALESCE(
           (SELECT COUNT(*) 
            FROM Posts PO 
            WHERE PO.OwnerUserId = U.Id AND PO.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'), 
           0) AS RecentPostsCount
FROM Users U
JOIN CombinedRanks R ON U.Id = R.UserId
WHERE U.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
ORDER BY R.Reputation DESC, R.TotalViews DESC;