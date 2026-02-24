
WITH UserBadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
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
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        COUNT(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 END) AS TagWikis,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPostBadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UBS.BadgeCount,
        UBS.GoldBadges,
        UBS.SilverBadges,
        UBS.BronzeBadges,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TagWikis,
        PS.TotalViews,
        PS.TotalScore
    FROM 
        UserBadgeSummary UBS
    JOIN 
        PostStatistics PS ON UBS.UserId = PS.OwnerUserId 
    JOIN 
        Users U ON UBS.UserId = U.Id
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TagWikis,
    TotalViews,
    TotalScore,
    CASE 
        WHEN TotalPosts > 0 THEN TotalScore / CAST(TotalPosts AS FLOAT) 
        ELSE 0 
    END AS AvgScorePerPost
FROM 
    UserPostBadgeSummary
ORDER BY 
    AvgScorePerPost DESC,
    BadgeCount DESC
LIMIT 10;
