
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
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
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        PD.*,
        RANK() OVER (PARTITION BY PD.AcceptedAnswerId ORDER BY PD.Score DESC) AS Rank
    FROM 
        PostDetails PD
    WHERE 
        PD.ViewCount > 100 AND 
        (PD.Score > 0 OR PD.ViewCount > 500)
)
SELECT 
    U.DisplayName,
    COUNT(DISTINCT FP.PostId) AS ActivePostCount,
    SUM(FP.TotalBounty) AS TotalBountyEarned,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges
FROM 
    UserBadges UB
JOIN 
    Users U ON U.Id = UB.UserId
LEFT JOIN 
    FilteredPosts FP ON U.Id IN (
        SELECT 
            DISTINCT O.OwnerUserId 
        FROM 
            Posts O 
        WHERE 
            O.OwnerUserId IS NOT NULL
    )
WHERE 
    UB.BadgeCount > 0
GROUP BY 
    U.DisplayName, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
HAVING 
    COUNT(DISTINCT FP.PostId) > 5
ORDER BY 
    TotalBountyEarned DESC;
