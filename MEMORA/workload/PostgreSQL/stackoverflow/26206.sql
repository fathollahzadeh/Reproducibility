WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalBadges DESC) AS BadgeRank
    FROM 
        UserBadges
),
ActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(AP.PostCount, 0) AS PostCount,
        COALESCE(AP.Questions, 0) AS Questions,
        COALESCE(AP.Answers, 0) AS Answers,
        COALESCE(AP.TotalViews, 0) AS TotalViews,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        RANK() OVER (ORDER BY COALESCE(AP.PostCount, 0) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        ActivePosts AP ON U.Id = AP.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.Questions,
    UA.Answers,
    UA.TotalViews,
    UA.TotalBadges,
    TB.GoldBadges,
    TB.SilverBadges,
    TB.BronzeBadges,
    UA.ActivityRank,
    TB.BadgeRank
FROM 
    UserActivity UA
JOIN 
    TopUsers TB ON UA.UserId = TB.UserId
WHERE 
    UA.TotalViews > 1000 
ORDER BY 
    UA.ActivityRank, TB.BadgeRank
LIMIT 10;