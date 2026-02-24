
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
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(US.PostCount, 0) AS PostCount,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN PostStatistics US ON U.Id = US.OwnerUserId
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
)
SELECT 
    UP.DisplayName,
    UP.PostCount,
    UP.BadgeCount,
    COALESCE(UPB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UPB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UPB.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN UP.PostCount > 50 THEN 'Prolific'
        WHEN UP.PostCount BETWEEN 20 AND 50 THEN 'Active'
        WHEN UP.PostCount BETWEEN 1 AND 19 THEN 'Newcomer'
        ELSE 'No Posts'
    END AS UserStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = UP.UserId) AS TotalComments
FROM UserPerformance UP
LEFT JOIN UserBadgeCounts UPB ON UP.UserId = UPB.UserId
ORDER BY UP.PostCount DESC, UP.BadgeCount DESC
LIMIT 10;
