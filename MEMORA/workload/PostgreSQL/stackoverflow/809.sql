
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScore AS (
    SELECT 
        P.OwnerUserId,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        UB.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalScore, 0) DESC, UB.BadgeCount DESC) AS Rank
    FROM UserBadges UB
    LEFT JOIN PostScore PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalScore,
    T.BadgeCount,
    CASE 
        WHEN T.TotalScore >= 100 THEN 'High Contributor'
        WHEN T.TotalScore BETWEEN 50 AND 99 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM TopUsers T
WHERE T.Rank <= 10
ORDER BY T.Rank;
