
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    MAX(b.Date) AS LatestBadgeDate
FROM 
    PostHierarchy ph
LEFT JOIN 
    Comments c ON ph.PostId = c.PostId
LEFT JOIN 
    Votes v ON ph.PostId = v.PostId
LEFT JOIN 
    Badges b ON b.UserId = ph.PostId  
WHERE 
    ph.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
GROUP BY 
    ph.PostId, ph.Title, ph.PostTypeId, ph.ParentId, ph.CreationDate, ph.Level
HAVING 
    COUNT(DISTINCT c.Id) > 0 OR COUNT(DISTINCT v.Id) > 0
ORDER BY 
    ph.Level, CommentCount DESC, ph.Title
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
