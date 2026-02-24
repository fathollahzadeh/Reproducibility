
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC NULLS LAST) AS ScoreRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseHistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PostLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)

SELECT 
    u.DisplayName,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(cpc.CloseHistoryCount, 0) AS CloseCount,
    COALESCE(plc.RelatedCount, 0) AS RelatedPostCount,
    CASE 
        WHEN pd.ScoreRank IS NOT NULL AND pd.ScoreRank < 5 THEN 'Top Performer'
        ELSE 'Regular Contributor'
    END AS UserType
FROM 
    Users u
JOIN 
    RankedPosts pd ON u.Id = pd.OwnerUserId
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    ClosedPosts cpc ON pd.PostId = cpc.PostId
LEFT JOIN 
    PostLinkCounts plc ON pd.PostId = plc.PostId
WHERE 
    u.Reputation > 1000
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY 
    COALESCE(pd.Score, 0) DESC,
    pb.BadgeCount DESC,
    u.DisplayName;
