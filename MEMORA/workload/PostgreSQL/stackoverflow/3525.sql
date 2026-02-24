WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 0
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    UP.DisplayName,
    UP.Reputation,
    RB.PostId,
    RB.Title,
    RB.CreationDate,
    RB.Score,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges
FROM 
    Users UP
LEFT JOIN 
    RankedPosts RB ON UP.Id = RB.OwnerUserId AND RB.ScoreRank = 1
LEFT JOIN 
    UserBadges UB ON UP.Id = UB.UserId
WHERE 
    UP.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND (UB.GoldBadges > 0 OR UB.SilverBadges > 1 OR UB.BronzeBadges > 2)
ORDER BY 
    UB.GoldBadges DESC, 
    UB.SilverBadges DESC, 
    RB.Score DESC
LIMIT 10;