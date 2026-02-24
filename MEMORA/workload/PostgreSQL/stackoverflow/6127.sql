WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
    GROUP BY 
        OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    p.Title,
    p.CreationDate,
    p.Score,
    phd.EditCount,
    phd.LastEditDate
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.OwnerUserId
JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId
JOIN 
    PostHistoryDetails phd ON p.PostId = phd.PostId
ORDER BY 
    tu.TotalScore DESC, 
    tu.PostCount DESC, 
    p.Score DESC
LIMIT 10;