WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
ActivePostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        P.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY 
        P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    R.DisplayName,
    R.Reputation,
    A.TotalPosts,
    A.TotalComments,
    COALESCE(A.TotalBounty, 0) AS TotalBounty,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    R.UserRank
FROM 
    RankedUsers R
LEFT JOIN 
    ActivePostStats A ON R.Id = A.OwnerUserId
LEFT JOIN 
    UserBadges UB ON R.Id = UB.UserId
WHERE 
    R.UserRank <= 100
ORDER BY 
    R.Reputation DESC, 
    A.TotalPosts DESC NULLS LAST,
    R.DisplayName
LIMIT 50;