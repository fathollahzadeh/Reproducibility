
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount 
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.Score, 
        P.ViewCount,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 YEAR' 
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.ViewCount, P.CreationDate
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS ActivePostCount,
        COALESCE(SUM(CASE WHEN U.Views IS NULL THEN 0 END), 0) AS InactiveUsers,
        COALESCE(SUM(CASE WHEN U.Reputation BETWEEN 0 AND 100 THEN 1 ELSE 0 END), 0) AS LowReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    UB.UserId,
    UB.BadgeCount,
    UB.GoldBadgeCount,
    UB.SilverBadgeCount,
    UB.BronzeBadgeCount,
    PA.TotalBounty,
    PA.CommentCount,
    PA.Score,
    PA.ViewCount,
    COALESCE(UA.ActivePostCount, 0) AS ActivePostCount,
    UA.InactiveUsers,
    UA.LowReputation,
    (CASE 
        WHEN UA.ActivePostCount = 0 AND UA.LowReputation > 10 THEN 'Needs Improvement'
        WHEN UB.BadgeCount > 5 THEN 'Veteran'
        ELSE 'New Member' 
    END) AS UserStatus
FROM 
    UserBadges UB
LEFT JOIN 
    PostStatistics PA ON UB.UserId = PA.OwnerUserId
LEFT JOIN 
    UserActivity UA ON UB.UserId = UA.UserId
WHERE 
    PA.RecentPostRank <= 5 
    OR (PA.CommentCount > 10 AND UB.BadgeCount > 0) 
    OR (PA.TotalBounty IS NULL AND UB.UserId NOT IN (SELECT UserId FROM Badges)) 
ORDER BY 
    UB.BadgeCount DESC, 
    PA.ViewCount DESC;
