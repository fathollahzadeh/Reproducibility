WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 100
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostLinksRank AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        COUNT(pl.Id) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId, pl.RelatedPostId
    HAVING 
        COUNT(pl.Id) > 5
),
FilteredComments AS (
    SELECT 
        c.PostId, 
        c.UserId,
        LAG(c.UserId) OVER (PARTITION BY c.PostId ORDER BY c.CreationDate) AS PrevUserId,
        COUNT(*) OVER (PARTITION BY c.PostId) AS TotalComments
    FROM 
        Comments c
    WHERE 
        c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
        AND c.UserId IS NOT NULL
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(pl.LinkCount, 0) AS LinkCount,
    fc.TotalComments,
    CASE 
        WHEN fc.TotalComments > 0 AND fc.PrevUserId IS NOT NULL THEN 'Active Discussion'
        ELSE 'No Recent Activity'
    END AS DiscussionStatus
FROM 
    RankedPosts r
LEFT JOIN 
    UserBadges ub ON r.OwnerUserId = ub.UserId
LEFT JOIN 
    PostLinksRank pl ON r.PostId = pl.PostId
LEFT JOIN 
    FilteredComments fc ON r.PostId = fc.PostId
WHERE 
    r.RankByScore <= 5
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;