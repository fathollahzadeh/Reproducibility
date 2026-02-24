
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
        AND p.Score > 0
        AND p.ViewCount IS NOT NULL
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostLinksFilter AS (
    SELECT 
        pl.PostId, 
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount 
    FROM 
        PostLinks pl 
    GROUP BY 
        pl.PostId
),

ClosedPosts AS (
    SELECT 
        p.Id,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.LastActivityDate,
    au.DisplayName,
    au.Reputation,
    au.BadgeCount,
    pl.RelatedPostCount,
    cp.CloseCount,
    CASE 
        WHEN au.ActivePostCount > 5 THEN 'Highly Active'
        WHEN au.ActivePostCount BETWEEN 1 AND 5 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS UserActivityLevel
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
LEFT JOIN 
    PostLinksFilter pl ON rp.PostId = pl.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.Id
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.LastActivityDate DESC;
