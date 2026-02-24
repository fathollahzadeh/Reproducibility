
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),

RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id) FILTER (WHERE C.Id IS NOT NULL), 0) AS CommentCount,
        COALESCE(P.ViewCount, 0) AS ViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
),

PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12)  
    GROUP BY 
        PH.PostId
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
)

SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.UserRank,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.Score AS PostScore,
    RP.ViewCount,
    PHC.HistoryCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
FROM 
    RankedUsers RU
LEFT JOIN 
    RecentPosts RP ON RP.OwnerUserId = RU.Id
LEFT JOIN 
    PostHistoryCounts PHC ON PHC.PostId = RP.PostId
LEFT JOIN 
    UserBadges UB ON UB.UserId = RU.Id
WHERE 
    (RU.Reputation > 1000 OR RP.ViewCount > 100)
    AND (RP.Score IS NOT NULL OR RP.Score < 0)  
ORDER BY 
    RU.UserRank, RP.CreationDate DESC
LIMIT 50;
