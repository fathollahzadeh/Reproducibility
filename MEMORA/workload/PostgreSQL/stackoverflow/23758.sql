WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM
        Posts P
    GROUP BY
        P.OwnerUserId
),
ClosedPostCounts AS (
    SELECT
        Ph.UserId,
        COUNT(DISTINCT Ph.PostId) AS ClosedPosts
    FROM
        PostHistory Ph
    WHERE
        Ph.PostHistoryTypeId = 10 
    GROUP BY
        Ph.UserId
),
CombinedStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(CPC.ClosedPosts, 0) AS ClosedPosts
    FROM
        Users U
    LEFT JOIN
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN
        PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN
        ClosedPostCounts CPC ON U.Id = CPC.UserId
)
SELECT
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    PostCount,
    TotalScore,
    TotalViews,
    ClosedPosts,
    CASE 
        WHEN Reputation > 1000 THEN 'High Reputation' 
        ELSE 'Newbie' 
    END AS UserLevel,
    CASE 
        WHEN TotalScore < 0 THEN 'Negative Score' 
        WHEN TotalScore BETWEEN 0 AND 100 THEN 'Low Score'
        WHEN TotalScore BETWEEN 101 AND 500 THEN 'Moderate Score' 
        ELSE 'High Score' 
    END AS ScoreCategory,
    CONCAT('User: ', DisplayName, ' has total views: ', TotalViews) AS UserViewMessage,
    NULLIF((BadgeCount - (ClosedPosts + PostCount)), 0) AS BadgeDeficiency
FROM 
    CombinedStatistics
WHERE 
    (BadgeCount > 0 OR ClosedPosts > 0) 
    AND Reputation IS NOT NULL
ORDER BY 
    Reputation DESC, TotalScore ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;