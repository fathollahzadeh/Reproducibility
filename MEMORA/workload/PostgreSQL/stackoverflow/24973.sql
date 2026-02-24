WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.OwnerUserId = b.UserId
    GROUP BY 
        rp.PostId, rp.OwnerUserId
),
AggregateData AS (
    SELECT 
        bw.PostId,
        bw.BadgeCount,
        bw.GoldBadges,
        bw.SilverBadges,
        bw.BronzeBadges,
        p.Tags,
        COUNT(c.Id) FILTER (WHERE c.Score > 0) AS PositiveComments,
        COUNT(c.Id) FILTER (WHERE c.Score < 0) AS NegativeComments,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM 
        PostWithBadges bw
    JOIN 
        Posts p ON bw.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        bw.PostId, bw.BadgeCount, bw.GoldBadges, bw.SilverBadges, bw.BronzeBadges, p.Tags
)
SELECT 
    ad.PostId,
    ad.BadgeCount,
    ad.GoldBadges,
    ad.SilverBadges,
    ad.BronzeBadges,
    ad.Tags,
    ad.PositiveComments,
    ad.NegativeComments,
    ad.RelatedPosts,
    CASE 
        WHEN ad.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN ad.RelatedPosts = 0 THEN 'No Related Posts'
        ELSE 'Has Related Posts'
    END AS RelatedStatus
FROM 
    AggregateData ad
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE ad.PostId = p.Id AND p.PostTypeId = 1
          AND p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    )
    AND (ad.PositiveComments > 5 OR ad.NegativeComments <= 3)
ORDER BY 
    ad.BadgeCount DESC, ad.PositiveComments DESC, ad.NegativeComments ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
