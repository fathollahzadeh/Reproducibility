WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserRecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
)

SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    UB.BadgeCount,
    URP.Title AS RecentPostTitle,
    URP.CreationDate AS RecentPostDate
FROM 
    RankedUsers RU
LEFT JOIN 
    UserBadges UB ON RU.UserId = UB.UserId
LEFT JOIN 
    UserRecentPosts URP ON RU.UserId = URP.OwnerUserId AND URP.RecentPostRank = 1
WHERE 
    RU.Rank <= 10;