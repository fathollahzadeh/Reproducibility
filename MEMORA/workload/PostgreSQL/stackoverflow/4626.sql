WITH UserReputation AS (
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
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        RP.OwnerUserId,
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RANK() OVER (PARTITION BY RP.OwnerUserId ORDER BY RP.ViewCount DESC) AS RankByViews
    FROM 
        RecentPosts RP
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UR.BadgeCount,
    UR.GoldBadges,
    UR.SilverBadges,
    UR.BronzeBadges,
    TP.Title,
    TP.ViewCount
FROM 
    UserReputation UR
LEFT JOIN 
    TopPosts TP ON UR.UserId = TP.OwnerUserId AND TP.RankByViews = 1
INNER JOIN 
    Users U ON U.Id = UR.UserId
WHERE 
    UR.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
    OR TP.ViewCount IS NOT NULL
ORDER BY 
    U.Reputation DESC,
    TP.ViewCount DESC NULLS LAST
LIMIT 100;