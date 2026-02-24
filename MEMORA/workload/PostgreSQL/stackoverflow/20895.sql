WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        UBS.UserId,
        UBS.DisplayName,
        UBS.BadgeCount,
        UBS.GoldBadges,
        UBS.SilverBadges,
        UBS.BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore
    FROM 
        UserBadgeStats UBS
    LEFT JOIN 
        PostStats PS ON UBS.UserId = PS.OwnerUserId
),
RankedStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, AvgScore DESC) AS PostRank
    FROM 
        CombinedStats
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
    AvgScore,
    PostRank
FROM 
    RankedStats
WHERE 
    BadgeCount > 0 AND 
    (TotalPosts > 0 OR Questions > 0)
ORDER BY 
    PostRank, BadgeCount DESC;