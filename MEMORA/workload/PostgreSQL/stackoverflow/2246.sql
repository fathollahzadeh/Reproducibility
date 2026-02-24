WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PS.OwnerUserId,
        PS.PostCount,
        PS.TotalViews,
        PS.AvgScore,
        ROW_NUMBER() OVER (ORDER BY PS.PostCount DESC) AS PostRank
    FROM 
        PostStats PS
),
UserInfo AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(RP.PostCount, 0) AS PostCount,
        COALESCE(RP.TotalViews, 0) AS TotalViews,
        COALESCE(RP.AvgScore, 0) AS AvgScore,
        UB.BadgeCount,
        UB.GoldCount,
        UB.SilverCount,
        UB.BronzeCount
    FROM 
        UserBadges UB
    LEFT JOIN 
        RankedPosts RP ON UB.UserId = RP.OwnerUserId
)
SELECT 
    UI.DisplayName,
    UI.PostCount,
    UI.TotalViews,
    UI.AvgScore,
    (CASE 
        WHEN UI.BadgeCount > 10 THEN 'Expert'
        WHEN UI.BadgeCount > 5 THEN 'Intermediate'
        ELSE 'Novice'
    END) AS ExperienceLevel,
    (CASE 
        WHEN UI.TotalViews > 10000 THEN 'Highly Visible'
        ELSE 'Moderate Visibility'
    END) AS VisibilityStatus
FROM 
    UserInfo UI
WHERE 
    UI.PostCount > 0
ORDER BY 
    UI.PostCount DESC, UI.TotalViews DESC;


