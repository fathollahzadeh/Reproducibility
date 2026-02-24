
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B 
    GROUP BY 
        B.UserId
), PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts P 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
), UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PS.TotalPosts,
        PS.TotalUpvotes,
        PS.TotalDownvotes,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        CASE WHEN U.Reputation > 5000 THEN 'Elite' ELSE 'Novice' END AS UserTier
    FROM 
        Users U
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalUpvotes, 
    U.TotalDownvotes, 
    U.GoldBadges, 
    U.SilverBadges, 
    U.BronzeBadges,
    U.UserTier, 
    R.UserRank
FROM 
    UserPerformance U
JOIN 
    RankedUsers R ON U.UserId = R.UserId
WHERE 
    U.TotalPosts IS NOT NULL 
    AND U.TotalUpvotes >= 10 
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.UserId = U.UserId AND V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    )
ORDER BY 
    R.UserRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
