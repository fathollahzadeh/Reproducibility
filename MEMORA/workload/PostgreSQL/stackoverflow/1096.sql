
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        RANK() OVER (ORDER BY COALESCE(SUM(p.ViewCount), 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    ru.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tu.TotalViews,
    COALESCE(rh.HistoryTypes, 'No History') AS PostHistoryTypes
FROM 
    RankedPosts rp
JOIN 
    Users ru ON rp.OwnerUserId = ru.Id
LEFT JOIN 
    TopUsers tu ON ru.Id = tu.Id
LEFT JOIN 
    RecentPostHistory rh ON rp.Id = rh.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC
FETCH FIRST 20 ROWS ONLY;
