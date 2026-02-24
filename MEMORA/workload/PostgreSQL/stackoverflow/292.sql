
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    R.Title,
    R.CreationDate,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.PostId = R.PostId 
       AND C.UserId IS NOT NULL) AS CommentCount,
    COALESCE((SELECT AVG(V.BountyAmount) 
              FROM Votes V 
              WHERE V.PostId = R.PostId 
                AND V.VoteTypeId IN (8, 9)), 0) AS AverageBounty
FROM 
    UserBadges UB
JOIN 
    RecentPosts R ON UB.UserId = R.OwnerUserId
JOIN 
    Users U ON U.Id = R.OwnerUserId
WHERE 
    R.rn = 1
ORDER BY 
    UB.GoldBadges DESC, UB.SilverBadges DESC, UB.BronzeBadges DESC
LIMIT 10;
