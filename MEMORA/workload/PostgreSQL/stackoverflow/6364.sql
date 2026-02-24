
WITH UserBadgeCounts AS (
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
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews,
        COUNT(DISTINCT P.Tags) AS UniqueTags
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViews, 0) AS AvgViews,
        COALESCE(PS.UniqueTags, 0) AS UniqueTags
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalScore,
    AvgViews,
    UniqueTags
FROM CombinedStatistics
WHERE PostCount > 10
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 50;
