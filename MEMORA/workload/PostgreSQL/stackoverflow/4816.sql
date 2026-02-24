WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName,
        u.Reputation,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(v.BountyAmount) > 0
)
SELECT 
    rp.Title,
    rp.Score,
    rp.CommentCount,
    u.DisplayName AS PostOwner,
    u.Reputation AS OwnerReputation,
    COALESCE(phs.ClosureCount, 0) AS PostClosureCount,
    phs.LastModifiedDate,
    tu.TotalBounty
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
LEFT JOIN 
    TopUsers tu ON u.Id = tu.Id
WHERE 
    rp.UserPostRank = 1 
    AND rp.Score > 10
    AND (phs.LastModifiedDate IS NULL OR phs.LastModifiedDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    rp.Score DESC, 
    u.Reputation DESC;