WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserPostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(UPM.TotalPosts, 0) AS TotalPosts,
        COALESCE(UPM.Questions, 0) AS Questions,
        COALESCE(UPM.Answers, 0) AS Answers,
        COALESCE(UPM.TotalViews, 0) AS TotalViews,
        COALESCE(UPM.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        UserPostMetrics UPM ON U.Id = UPM.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, BadgeCount DESC, TotalViews DESC) AS Rank
    FROM 
        CombinedMetrics
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    AverageScore,
    Rank
FROM 
    RankedUsers
WHERE 
    Rank <= 100
ORDER BY 
    Rank;
