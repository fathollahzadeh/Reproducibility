
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS UserRank
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.Comment, '; ' ORDER BY ph.CreationDate) AS EditComments
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    pu.DisplayName AS UserName,
    rp.Title,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    phs.EditCount AS TotalEdits,
    phs.LastEditDate,
    phs.EditComments,
    tu.TotalBounties,
    tu.UserRank
FROM 
    RankedPosts rp
JOIN 
    Users pu ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
JOIN 
    TopUsers tu ON pu.Id = tu.Id
WHERE 
    rp.rn = 1 
    AND rp.CommentCount > 0
ORDER BY 
    tu.UserRank, rp.Score DESC
LIMIT 50;
