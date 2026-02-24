WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankByScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostLinksDetails AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedPostCount,
        SUM(CASE WHEN LT.Name = 'Duplicate' THEN 1 ELSE 0 END) AS DuplicateCount
    FROM 
        PostLinks PL
    JOIN 
        LinkTypes LT ON PL.LinkTypeId = LT.Id
    GROUP BY 
        PL.PostId
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.RankByScore,
        UB.BadgeCount,
        UB.BadgeNames,
        PLD.RelatedPostCount,
        PLD.DuplicateCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        UserBadges UB ON RP.OwnerUserId = UB.UserId
    LEFT JOIN 
        PostLinksDetails PLD ON RP.PostId = PLD.PostId
    WHERE 
        RP.RankByScore <= 10
)
SELECT 
    FR.PostId,
    FR.Title,
    COALESCE(FR.Score, 0) AS PostScore,
    COALESCE(FR.ViewCount, 0) AS TotalViews,
    COALESCE(FR.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(FR.RelatedPostCount, 0) AS TotalRelatedPosts,
    FR.DuplicateCount AS TotalDuplicates,
    CASE 
        WHEN FR.BadgeCount IS NULL THEN 'No Badges'
        ELSE FR.BadgeNames
    END AS UserBadges
FROM 
    FinalResults FR
ORDER BY 
    FR.Score DESC, FR.ViewCount DESC;