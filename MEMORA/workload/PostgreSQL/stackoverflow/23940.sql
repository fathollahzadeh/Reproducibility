WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.PostTypeId,
        P.Score,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS RankPerType
    FROM 
        Posts P
    WHERE 
        P.Score IS NOT NULL
),

UserBadges AS (
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

CloseReasonStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(CASE WHEN PH.Comment IS NOT NULL THEN PH.Comment ELSE 'Unspecified' END, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
),

AppendedData AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerUserId,
        CB.CloseReasonCount,
        CB.CloseReasons,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        CASE 
            WHEN RP.PostTypeId = 1 AND RP.RankPerType <= 5 THEN 'Top Question'
            WHEN RP.PostTypeId = 2 AND RP.Score > 10 THEN 'Popular Answer'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts RP
    LEFT JOIN 
        CloseReasonStats CB ON RP.PostId = CB.PostId
    LEFT JOIN 
        UserBadges UB ON RP.OwnerUserId = UB.UserId
)

SELECT 
    AD.Title,
    AD.CreationDate,
    AD.CloseReasonCount,
    AD.CloseReasons,
    AD.BadgeCount,
    AD.GoldBadges,
    AD.SilverBadges,
    AD.BronzeBadges,
    AD.PostCategory,
    CASE 
        WHEN AD.CloseReasonCount IS NULL THEN 'No Close Reason Available'
        ELSE 'Has Close Reason: ' || AD.CloseReasons
    END AS CloseStatus
FROM 
    AppendedData AD
WHERE 
    AD.BadgeCount > 0
ORDER BY 
    AD.CreationDate DESC
LIMIT 100;