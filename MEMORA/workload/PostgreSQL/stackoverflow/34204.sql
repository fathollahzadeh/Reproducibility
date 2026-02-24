
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)

, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    u.DisplayName AS Owner,
    ur.TotalBounty,
    ur.UpVotes,
    ur.DownVotes,
    CASE 
        WHEN ur.UpVotes IS NOT NULL AND ur.DownVotes IS NOT NULL 
            THEN (ur.UpVotes - ur.DownVotes) 
        ELSE NULL 
    END AS NetVotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT p2.Id) AS AnswerCount,
    MAX(uh.CreationDate) AS LastActivityDate
FROM 
    PostHierarchy ph
LEFT JOIN 
    Posts p2 ON ph.PostId = p2.ParentId
LEFT JOIN 
    Users u ON ph.PostId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    Comments c ON c.PostId = ph.PostId
LEFT JOIN 
    (SELECT 
         PostId, CreationDate 
     FROM 
         PostHistory 
     WHERE 
         PostHistoryTypeId IN (10, 11)) uh ON uh.PostId = ph.PostId
GROUP BY 
    ph.PostId, ph.Title, ph.Level, u.DisplayName, ur.TotalBounty, ur.UpVotes, ur.DownVotes
HAVING 
    COUNT(DISTINCT c.Id) > 0 OR COUNT(DISTINCT p2.Id) > 0
ORDER BY 
    ph.Level, NetVotes DESC;
