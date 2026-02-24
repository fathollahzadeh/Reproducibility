WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE 
            WHEN P.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS Questions,
        SUM(CASE 
            WHEN P.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS Answers,
        SUM(CASE 
            WHEN P.PostTypeId = 3 THEN 1 
            ELSE 0 
        END) AS Wikis,
        COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.Wikis,
    U.TotalScore,
    COALESCE(B.TotalBadges, 0) AS TotalBadges,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserPostStats U
LEFT JOIN 
    UserBadgeStats B ON U.UserId = B.UserId
ORDER BY 
    U.TotalScore DESC, U.TotalPosts DESC
LIMIT 100;