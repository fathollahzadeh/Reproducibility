WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseActionCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pp.Title,
    pp.ViewCount,
    cp.CloseActionCount,
    COALESCE(cp.CloseActionCount, 0) AS CloseCount,
    CASE 
        WHEN ub.BadgeCount > 5 THEN 'Highly Decorated'
        WHEN ub.BadgeCount BETWEEN 3 AND 5 THEN 'Moderately Decorated'
        ELSE 'New User'
    END AS UserStatus
FROM 
    UserBadges ub
LEFT JOIN 
    PostLinks pl ON ub.UserId = pl.RelatedPostId  
LEFT JOIN 
    PopularPosts pp ON pl.PostId = pp.Id
LEFT JOIN 
    ClosedPosts cp ON pp.Id = cp.PostId
WHERE 
    pp.RN <= 10 OR cp.CloseActionCount IS NOT NULL
ORDER BY 
    ub.BadgeCount DESC, pp.ViewCount DESC NULLS LAST;