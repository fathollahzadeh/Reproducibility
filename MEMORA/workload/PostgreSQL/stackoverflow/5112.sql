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
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
    ORDER BY 
        BadgeCount DESC
    LIMIT 10
),
UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        COUNT(CASE WHEN P.LastActivityDate >= cast('2024-10-01' as date) - INTERVAL '30 days' THEN 1 END) AS RecentActivity
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.BadgeCount,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UP.RecentActivity
FROM 
    TopUsers TU
JOIN 
    UserPosts UP ON TU.UserId = UP.OwnerUserId
ORDER BY 
    TU.BadgeCount DESC, UP.TotalPosts DESC;