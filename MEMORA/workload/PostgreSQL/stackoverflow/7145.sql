WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.Views AS UserViews,
        BS.BadgeCount,
        BS.GoldBadges,
        BS.SilverBadges,
        BS.BronzeBadges,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalViews,
        PS.TotalScore
    FROM 
        Users U
    JOIN 
        UserBadgeStats BS ON U.Id = BS.UserId
    JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.Reputation >= 1000
)
SELECT 
    DisplayName,
    Reputation,
    UserViews,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore
FROM 
    CombinedStats
ORDER BY 
    TotalScore DESC, UserViews DESC
LIMIT 10;