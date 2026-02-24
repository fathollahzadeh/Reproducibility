WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
    HAVING 
        MAX(ph.CreationDate) < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
    ORDER BY 
        TotalBounties DESC, TotalBadgeClass DESC
    LIMIT 5
)
SELECT 
    rp.PostRank,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(f.HistoryCount, 0) AS InactiveHistoryCount,
    COALESCE(tu.TotalBadgeClass, 0) AS UserTotalBadgeClass,
    CASE 
        WHEN rp.ViewCount = 0 THEN 'No Views'
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredPostHistory f ON rp.PostId = f.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;