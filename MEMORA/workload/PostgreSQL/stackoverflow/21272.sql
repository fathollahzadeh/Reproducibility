WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        P.OwnerUserId,
        COUNT(*) AS ClosedPostCount,
        STRING_AGG(DISTINCT CT.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    JOIN CloseReasonTypes CT ON CT.Id = CAST(PH.Comment AS INT)
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.UserId, P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(UB.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadgeCount,
        COALESCE(RP.TotalPosts, 0) AS TotalPosts,
        COALESCE(RP.Questions, 0) AS Questions,
        COALESCE(RP.Answers, 0) AS Answers,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
        CP.CloseReasons,
        RP.LastPostDate
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId
    LEFT JOIN ClosedPosts CP ON U.Id = CP.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        TotalPosts,
        Questions,
        Answers,
        ClosedPostCount,
        CloseReasons,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC, Questions DESC) AS PostRank
    FROM UserStats
)
SELECT 
    UserId,
    DisplayName,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    TotalPosts,
    Questions,
    Answers,
    ClosedPostCount,
    COALESCE(NULLIF(CloseReasons, ''), 'No closures') AS CloseReasons,
    LastPostDate,
    CASE 
        WHEN ClosedPostCount > 0 THEN 'Risk of Closure'
        WHEN GoldBadgeCount > 0 AND Questions = 0 THEN 'Gold Badge Holder, No Questions'
        ELSE 'Active User'
    END AS UserStatus,
    CASE 
        WHEN PostRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM RankedUsers
WHERE TotalPosts > 0
ORDER BY PostRank, LastPostDate DESC;