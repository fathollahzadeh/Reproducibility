
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(c.TotalComments, 0) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalComments
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.TotalComments,
    cu.ClosedBy,
    cu.ClosedDate,
    tu.DisplayName AS TopUser,
    tu.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN ClosedPosts cu ON rp.PostId = cu.PostId
LEFT JOIN TopUsers tu ON rp.Score > 10 
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.PostId ASC;
