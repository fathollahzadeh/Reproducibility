WITH UserBadges AS (
    SELECT 
        U.Id as UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserMetrics AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.TotalBadges,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        UP.TotalPosts,
        UP.Questions,
        UP.Answers,
        UP.TotalViewCount
    FROM UserBadges UB
    LEFT JOIN UserPosts UP ON UB.UserId = UP.OwnerUserId
)
SELECT 
    DM.DisplayName,
    DM.TotalBadges,
    DM.GoldBadges,
    DM.SilverBadges,
    DM.BronzeBadges,
    DM.TotalPosts,
    DM.Questions,
    DM.Answers,
    DM.TotalViewCount,
    RANK() OVER (ORDER BY DM.TotalViewCount DESC) AS ViewRank
FROM UserMetrics DM
WHERE DM.TotalBadges > 0
ORDER BY ViewRank, DM.TotalBadges DESC;
