
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViews,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        HighViews,
        AvgReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM UserActivity
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM Badges B
    GROUP BY B.UserId
),
FinalMetrics AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.PostCount,
        TU.Questions,
        TU.Answers,
        TU.HighViews,
        TU.AvgReputation,
        UB.BadgeCount,
        UB.HighestBadgeClass,
        TU.RankByPosts
    FROM TopUsers TU
    LEFT JOIN UserBadges UB ON TU.UserId = UB.UserId
)
SELECT 
    *,
    CASE 
        WHEN RankByPosts <= 10 THEN 'Top Contributor'
        WHEN BadgeCount > 5 THEN 'Veteran Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM FinalMetrics
ORDER BY RankByPosts, AvgReputation DESC;
