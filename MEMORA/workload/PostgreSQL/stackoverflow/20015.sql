
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP)) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title AS ClosedPostTitle
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
        AND ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP)) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT COALESCE(lt.Name, 'Unknown Link Type'), ', ') AS LinkTypes
    FROM 
        PostLinks pl
    LEFT JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.TotalPosts,
    cb.ClosedPostTitle,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ub.BadgeNames,
    COALESCE(pl.RelatedPostCount, 0) AS RelatedPostCount,
    pl.LinkTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    Users u ON u.Id = rp.ViewCount 
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
WHERE 
    (rp.Rank <= 5 OR cb.ClosedPostTitle IS NOT NULL) 
    AND (MOD(rp.ViewCount, 2) = 0 OR rp.Score > 10) 
ORDER BY 
    rp.Rank, 
    COALESCE(cb.ClosedPostTitle, 'Open') DESC;
