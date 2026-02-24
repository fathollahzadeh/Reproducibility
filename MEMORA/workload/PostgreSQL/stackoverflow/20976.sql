WITH UserBadges AS (
    SELECT
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Badges B
    GROUP BY
        B.UserId
),

ActivePosts AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM
        Posts P
    LEFT JOIN
        Comments C ON C.PostId = P.Id
    LEFT JOIN
        Votes V ON V.PostId = P.Id AND V.VoteTypeId IN (8, 9) 
    WHERE
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        P.Id, P.OwnerUserId, P.PostTypeId
),

EnrichedPosts AS (
    SELECT
        AP.PostId,
        U.DisplayName AS OwnerDisplayName,
        AP.CommentCount,
        AP.TotalBounty,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        CASE
            WHEN AP.TotalBounty > 0 THEN 'Has Bounty'
            ELSE 'No Bounty'
        END AS BountyStatus
    FROM
        ActivePosts AP
    JOIN
        Users U ON U.Id = AP.OwnerUserId
    LEFT JOIN
        UserBadges UB ON UB.UserId = AP.OwnerUserId
)

SELECT
    EP.PostId,
    EP.OwnerDisplayName,
    EP.CommentCount,
    EP.TotalBounty,
    EP.BountyStatus,
    CASE 
        WHEN EP.BountyStatus = 'Has Bounty' AND EP.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        WHEN EP.BountyStatus = 'Has Bounty' AND EP.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    COALESCE(EP.GoldBadges, 0) AS GoldBadges,
    COALESCE(EP.SilverBadges, 0) AS SilverBadges,
    COALESCE(EP.BronzeBadges, 0) AS BronzeBadges,
    ROW_NUMBER() OVER (PARTITION BY EP.BountyStatus ORDER BY EP.TotalBounty DESC) AS RankWithinBountyStatus
FROM
    EnrichedPosts EP
WHERE
    EP.CommentCount > 0
    AND EP.OwnerDisplayName IS NOT NULL
ORDER BY
    EP.TotalBounty DESC,
    EP.CommentCount DESC;