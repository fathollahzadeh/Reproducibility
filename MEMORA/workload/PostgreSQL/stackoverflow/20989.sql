
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS RN,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT ph.PostId) AS ClosedPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostLinkStats AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        SUM(CASE WHEN lt.Name = 'Duplicate' THEN 1 ELSE 0 END) AS DuplicateLinks
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
),

CombinedStats AS (
    SELECT 
        up.DisplayName,
        up.Reputation,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges,
        up.ClosedPosts,
        pls.RelatedPostCount,
        pls.DuplicateLinks,
        rp.RN,
        rp.PostCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats up ON rp.OwnerUserId = up.UserId
    LEFT JOIN 
        PostLinkStats pls ON rp.PostId = pls.PostId
    WHERE 
        rp.RN = 1
),

FinalResults AS (
    SELECT 
        *,
        CASE 
            WHEN Reputation >= 1000 THEN 'Expert'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserTier,
        ROUND(COALESCE(ViewCount / NULLIF(PostCount, 0), 0)::NUMERIC, 2) AS AvgViewsPerPost
    FROM 
        CombinedStats
)

SELECT 
    fr.DisplayName,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.GoldBadges,
    fr.SilverBadges,
    fr.BronzeBadges,
    fr.UserTier,
    fr.ClosedPosts,
    fr.RelatedPostCount,
    fr.DuplicateLinks,
    fr.AvgViewsPerPost,
    'Link Types: ' || STRING_AGG(DISTINCT lt.Name, ', ' ORDER BY lt.Name) AS LinkTypesInfo
FROM 
    FinalResults fr
LEFT JOIN 
    PostLinks pl ON fr.PostId = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
GROUP BY 
    fr.DisplayName, fr.Title, fr.CreationDate, fr.Score, fr.ViewCount, 
    fr.GoldBadges, fr.SilverBadges, fr.BronzeBadges, fr.UserTier,
    fr.ClosedPosts, fr.RelatedPostCount, fr.DuplicateLinks, fr.AvgViewsPerPost
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 10;
