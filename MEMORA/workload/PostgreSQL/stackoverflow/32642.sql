WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        C.UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(RP.PostCount, 0) AS RecentPostCount,
        COALESCE(TC.CommentCount, 0) AS RecentCommentCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCount UB ON U.Id = UB.UserId
    LEFT JOIN 
        (SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            RecentPosts
        WHERE 
            PostRank = 1
        GROUP BY 
            OwnerUserId) RP ON U.Id = RP.OwnerUserId
    LEFT JOIN 
        TopComments TC ON U.Id = TC.UserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalBadges,
    TU.RecentPostCount,
    TU.RecentCommentCount,
    CASE 
        WHEN TU.Reputation >= 1000 THEN 'Expert' 
        WHEN TU.Reputation >= 500 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS UserLevel
FROM 
    TopUsers TU
WHERE 
    TU.RecentPostCount > 0 OR TU.RecentCommentCount > 0
ORDER BY 
    TU.Reputation DESC, TU.TotalBadges DESC
LIMIT 10;