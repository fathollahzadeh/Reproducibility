
WITH UserBadges AS (
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
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalScore,
        PS.AvgViewCount
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.LastAccessDate > CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    UserId, 
    DisplayName, 
    BadgeCount, 
    TotalPosts, 
    Questions, 
    Answers, 
    TotalScore, 
    AvgViewCount
FROM 
    ActiveUsers
ORDER BY 
    TotalScore DESC, 
    BadgeCount DESC
LIMIT 100;
