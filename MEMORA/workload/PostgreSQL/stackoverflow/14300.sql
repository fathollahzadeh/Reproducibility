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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UBad.BadgeCount,
    UBad.GoldBadges,
    UBad.SilverBadges,
    UBad.BronzeBadges,
    PStats.TotalPosts,
    PStats.Questions,
    PStats.Answers,
    PStats.TagWikis
FROM 
    Users U
JOIN 
    UserBadges UBad ON U.Id = UBad.UserId
JOIN 
    PostStats PStats ON U.Id = PStats.OwnerUserId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC
LIMIT 100;