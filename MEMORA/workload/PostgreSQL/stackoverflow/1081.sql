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
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RankedUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        B.BadgeCount,
        P.TotalPosts,
        P.TotalScore,
        P.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY B.BadgeCount DESC, P.TotalScore DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    LEFT JOIN PostStatistics P ON U.Id = P.OwnerUserId
)
SELECT
    R.UserRank,
    R.DisplayName,
    COALESCE(R.BadgeCount, 0) AS BadgeCount,
    COALESCE(R.TotalPosts, 0) AS TotalPosts,
    COALESCE(R.TotalScore, 0) AS TotalScore,
    COALESCE(R.AvgViewCount, 0) AS AvgViewCount,
    CASE
        WHEN R.BadgeCount IS NULL THEN 'No Badges'
        WHEN R.BadgeCount > 10 THEN 'Veteran User'
        ELSE 'New User'
    END AS UserType
FROM RankedUsers R
WHERE R.UserRank <= 10
ORDER BY R.UserRank;
