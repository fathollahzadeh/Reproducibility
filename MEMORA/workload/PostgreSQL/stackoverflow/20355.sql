WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostActivities AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount,
        MAX(P.LastActivityDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
),
UserReputationAndActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(RP.CommentCount, 0) AS CommentCount,
        COALESCE(RP.HistoryCount, 0) AS HistoryCount,
        RP.LastActivity
    FROM 
        Users U
    LEFT JOIN 
        RecentPostActivities RP ON U.Id = RP.OwnerUserId
)
SELECT 
    UDA.UserId,
    UDA.DisplayName,
    UDA.Reputation,
    UDA.CommentCount,
    UDA.HistoryCount,
    UBC.BadgeCount AS TotalBadges,
    UBC.GoldBadgeCount,
    UBC.SilverBadgeCount,
    UBC.BronzeBadgeCount,
    CASE 
        WHEN UDA.LastActivity < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus,
    (SELECT AVG(V.BountyAmount) 
     FROM Votes V 
     WHERE V.UserId = UDA.UserId 
     AND V.VoteTypeId IN (8, 9) 
    ) AS AvgBountyAmount
FROM 
    UserReputationAndActivity UDA
JOIN 
    UserBadgeCounts UBC ON UDA.UserId = UBC.UserId
WHERE 
    UDA.Reputation > 1000
ORDER BY 
    UDA.Reputation DESC, 
    UBC.BadgeCount DESC;