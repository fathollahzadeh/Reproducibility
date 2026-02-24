WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS PostHistoryCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        MAX(ph.CreationDate) AS LastPostEditDate
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostLinksInfo AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypes
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.GoldBadgeCount,
    pgi.RelatedPostCount,
    pgi.LinkTypes,
    us.LastPostEditDate,
    CASE 
        WHEN us.PostHistoryCount IS NULL THEN 'No Post History'
        ELSE 'Has Post History'
    END AS PostHistoryStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostLinksInfo pgi ON rp.PostId = pgi.PostId
WHERE 
    (rp.Score > 10 OR rp.ViewCount > 100)
    AND us.Reputation IS NOT NULL
    AND (pgi.RelatedPostCount IS NULL OR pgi.RelatedPostCount < 5)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;