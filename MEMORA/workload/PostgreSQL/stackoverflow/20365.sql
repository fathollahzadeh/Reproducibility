WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS ViewsFromPosts,
        COALESCE(PS.AverageScore, 0) AS AveragePostScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(UB.BadgeCount, 0) DESC, COALESCE(PS.TotalViews, 0) DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.TotalBadges,
    C.TotalPosts,
    C.ViewsFromPosts,
    C.AveragePostScore,
    CASE 
        WHEN C.AveragePostScore IS NULL THEN 'No Score'
        WHEN C.AveragePostScore > 5 THEN 'High Scorer'
        ELSE 'Low Scorer' 
    END AS ScoreCategory,
    CASE 
        WHEN C.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM CombinedStats C
WHERE C.TotalPosts > 0
ORDER BY C.Rank
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;