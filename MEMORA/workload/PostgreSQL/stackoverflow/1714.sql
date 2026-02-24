WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS ClosedCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.UserId
),
RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(CP.ClosedCount, 0) AS ClosedCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalPosts, 0) DESC, COALESCE(UB.BadgeCount, 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN ClosedPosts CP ON U.Id = CP.UserId
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.BadgeCount,
    RU.TotalPosts,
    RU.ClosedCount,
    COALESCE((SELECT MAX(Score) FROM Posts WHERE OwnerUserId = RU.UserId), 0) AS MaxPostScore,
    CASE 
        WHEN RU.ClosedCount > 0 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM RankedUsers RU
WHERE RU.UserRank <= 10
ORDER BY RU.UserRank;
