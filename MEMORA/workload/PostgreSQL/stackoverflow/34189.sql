
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Depth,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    MAX(ph.CreationDate) AS LatestActivity
FROM 
    PostHierarchy ph
LEFT JOIN 
    Comments c ON c.PostId = ph.PostId
LEFT JOIN 
    Votes v ON v.PostId = ph.PostId AND v.VoteTypeId = 8  
LEFT JOIN 
    Votes v2 ON v2.PostId = ph.PostId AND v2.VoteTypeId = 6  
WHERE 
    v2.Id IS NULL  
GROUP BY 
    ph.PostId, ph.Title, ph.Depth, ph.CreationDate
HAVING 
    COUNT(c.Id) > 1 OR COALESCE(SUM(v.BountyAmount), 0) > 0
ORDER BY 
    ph.Depth, TotalBounty DESC;
