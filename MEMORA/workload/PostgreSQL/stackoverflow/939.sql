WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
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
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)

SELECT 
    U.DisplayName,
    U.Reputation,
    UB.TotalBadges,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.CommentCount AS RecentPostComments,
    CASE 
        WHEN RP.Score IS NULL THEN 'No Score' 
        ELSE CAST(RP.Score AS VARCHAR) 
    END AS PostScore
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RN = 1
WHERE 
    U.Location IS NOT NULL OR U.WebsiteUrl IS NOT NULL
ORDER BY 
    U.Reputation DESC, 
    RecentPostDate DESC NULLS LAST
LIMIT 100;