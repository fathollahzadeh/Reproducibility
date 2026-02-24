WITH RECURSIVE BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        (CASE 
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Experienced'
            ELSE 'Expert'
         END) AS ReputationLevel
    FROM 
        Users
),
RecentPostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        MAX(CreationDate) AS LastPostDate,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        OwnerUserId
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    COALESCE(BC.GoldBadges, 0) AS GoldBadges,
    COALESCE(BC.SilverBadges, 0) AS SilverBadges,
    COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
    UR.ReputationLevel,
    RP.PostCount,
    RP.LastPostDate,
    RP.TotalViews,
    PH.EditCount AS TotalEdits,
    PH.LastEditDate
FROM 
    Users U
LEFT JOIN 
    BadgeCounts BC ON U.Id = BC.UserId
JOIN 
    UserReputation UR ON U.Id = UR.Id
LEFT JOIN 
    RecentPostStats RP ON U.Id = RP.OwnerUserId
LEFT JOIN 
    PostHistoryCounts PH ON U.Id = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = PH.PostId
    )
WHERE 
    U.Reputation > 0
ORDER BY 
    U.Reputation DESC,
    TotalViews DESC,
    TotalEdits DESC
LIMIT 100;