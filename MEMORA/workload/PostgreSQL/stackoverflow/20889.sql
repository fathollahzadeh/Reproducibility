WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B 
    GROUP BY 
        B.UserId
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ViewCount,
        DENSE_RANK() OVER (ORDER BY P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
        AND P.ViewCount IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
JoinedData AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        PP.PostId,
        PP.Title,
        PP.ViewCount,
        C.CloseCount
    FROM 
        TopUsers U
    LEFT JOIN 
        UserBadges UB ON U.UserId = UB.UserId
    INNER JOIN 
        PopularPosts PP ON U.UserId = PP.OwnerUserId
    LEFT JOIN 
        ClosedPosts C ON PP.PostId = C.PostId
)
SELECT 
    JD.DisplayName,
    JD.Reputation,
    JD.GoldBadges,
    JD.SilverBadges,
    JD.BronzeBadges,
    JD.Title,
    JD.ViewCount,
    JD.CloseCount,
    CASE 
        WHEN JD.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN JD.Reputation > 2000 THEN 'Elite User'
        WHEN JD.Reputation BETWEEN 1000 AND 2000 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserCategory
FROM 
    JoinedData JD
WHERE 
    JD.ViewCount > 50
ORDER BY 
    JD.ViewCount DESC, JD.Reputation DESC
LIMIT 10;