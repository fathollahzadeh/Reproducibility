WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
ActiveUserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
CombinedData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views AS UserViews,
        COALESCE(UPC.PostCount, 0) AS PostCount,
        COALESCE(UPC.TotalViews, 0) AS PostViews,
        COALESCE(UPC.TotalScore, 0) AS PostScore,
        COALESCE(UPC.AvgScore, 0) AS AvgPostScore,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBC.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(UBC.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(UBC.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN ActiveUserPosts UPC ON U.Id = UPC.OwnerUserId
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    UserViews,
    PostCount,
    PostViews,
    PostScore,
    AvgPostScore,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM CombinedData
ORDER BY Reputation DESC, PostCount DESC, BadgeCount DESC
LIMIT 100;