
WITH RECURSIVE RecentPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
), TopUsers AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  
), ClosedPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosureDate,
        c.Name AS CloseReason
    FROM 
        Posts p 
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes c ON ph.Comment::INTEGER = c.Id
), PostStatistics AS (
    
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    cp.ClosureDate,
    cp.CloseReason,
    ps.TotalPosts,
    ps.AvgViews
FROM 
    RecentPosts rp
FULL OUTER JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    PostStatistics ps ON TRUE 
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC;
