WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PA.PostId,
        PA.OwnerUserId,
        PA.CommentCount,
        PA.TotalBounty,
        RANK() OVER (PARTITION BY PA.OwnerUserId ORDER BY PA.CommentCount DESC) AS CommentRank,
        DENSE_RANK() OVER (ORDER BY PA.TotalBounty DESC) AS BountyRank
    FROM 
        PostAggregates PA
),
UserDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        RP.PostId,
        RP.CommentCount,
        RP.TotalBounty,
        RP.CommentRank,
        RP.BountyRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    WHERE 
        U.Reputation > 0
)
SELECT 
    UD.DisplayName,
    UD.Reputation,
    UD.GoldBadges,
    UD.SilverBadges,
    UD.BronzeBadges,
    UD.CommentCount,
    CASE 
        WHEN UD.TotalBounty > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus,
    CASE 
        WHEN UD.CommentRank IS NULL THEN 'N/A'
        ELSE CAST(UD.CommentRank AS varchar)
    END AS CommentRank,
    CASE 
        WHEN UD.BountyRank IS NULL THEN 'N/A'
        ELSE CAST(UD.BountyRank AS varchar)
    END AS BountyRank
FROM 
    UserDetails UD
WHERE 
    (UD.CommentCount > 0 OR UD.TotalBounty > 0)
    AND 
    (UD.GoldBadges + UD.SilverBadges + UD.BronzeBadges) > 0
ORDER BY 
    UD.Reputation DESC, 
    UD.CommentCount DESC;