WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    tu.TotalPosts,
    tu.TotalViews
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    tu.TotalViews DESC, 
    tu.TotalPosts DESC
LIMIT 10;