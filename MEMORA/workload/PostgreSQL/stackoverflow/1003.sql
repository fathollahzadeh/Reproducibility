WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        H.Name AS HistoryType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes H ON PH.PostHistoryTypeId = H.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND 
        H.Name = 'Post Closed'
)
SELECT 
    U.DisplayName,
    UB.BadgeCount,
    COALESCE(UB.BadgeNames, 'No badges') AS BadgeNames,
    RP.Title AS RecentPostTitle,
    RP.ViewCount AS RecentPostViews,
    CP.CreationDate AS ClosedPostDate,
    CP.HistoryType AS ClosedPostHistoryType
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RowNum = 1
LEFT JOIN 
    ClosedPosts CP ON U.Id = CP.PostId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    RP.ViewCount DESC
LIMIT 10;