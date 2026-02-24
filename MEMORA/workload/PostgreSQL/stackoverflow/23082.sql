WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostHistoryRanked AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(ph.Comment, '; ') AS CommentsHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id
    HAVING 
        SUM(v.BountyAmount) >= 1000
)
SELECT 
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerName,
    rp.Score,
    COALESCE(phr.ChangeCount, 0) AS ChangeCount,
    COALESCE(phr.CommentsHistory, 'No history') AS CommentsHistory,
    tu.DisplayName AS TopBountyUser,
    tu.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryRanked phr ON rp.PostId = phr.PostId
LEFT JOIN 
    TopUsers tu ON u.Id = tu.Id
WHERE 
    rp.Rank <= 5 
    AND (rp.CommentCount > 0 OR phr.ChangeCount > 0)
ORDER BY 
    rp.CreationDate DESC;