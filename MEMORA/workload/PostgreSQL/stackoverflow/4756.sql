WITH UserBadgeCounts AS (
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
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        PS.LastPostDate
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN PostSummary PS ON U.Id = PS.OwnerUserId
    WHERE U.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RankedUsers AS (
    SELECT 
        A.*,
        RANK() OVER (ORDER BY A.Reputation DESC, A.BadgeCount DESC) AS UserRank
    FROM ActiveUsers A
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.BadgeCount,
    RU.TotalPosts,
    RU.TotalViews,
    RU.LastPostDate,
    CASE 
        WHEN RU.UserRank <= 10 THEN 'Top User'
        WHEN RU.Reputation > 1000 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserCategory,
    CASE 
        WHEN RU.LastPostDate IS NULL THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = RU.UserId) AS CommentCount
FROM RankedUsers RU
WHERE RU.TotalPosts > 0
ORDER BY RU.UserRank
LIMIT 20;