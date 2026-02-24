
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '2 years'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    pu.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    ph.HistoryCount,
    tu.TotalViews,
    tu.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users pu ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    PostHistoryAggregation ph ON rp.Id = ph.PostId
JOIN 
    TopUsers tu ON pu.Id = tu.UserId
WHERE 
    rp.rn = 1 
    AND (tu.TotalViews > 1000 OR tu.BadgeCount > 3)
ORDER BY 
    rp.ViewCount DESC, 
    pu.DisplayName ASC
LIMIT 10 OFFSET 0;
