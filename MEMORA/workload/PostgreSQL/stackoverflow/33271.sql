
WITH RECURSIVE RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),

PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

PostStatistics AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        ph.Level,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 5), 0) AS FavoriteCount
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteCounts pvc ON ph.PostId = pvc.PostId
)

SELECT 
    ps.Title,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.Level,
    CASE 
        WHEN ps.Level = 1 THEN 'Top Level'
        WHEN ps.Level = 2 THEN 'Sub Post'
        ELSE CONCAT('Nested Level ', ps.Level)
    END AS PostLevelDescription,
    STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')'), ', ') AS ActiveCommenters
FROM 
    PostStatistics ps
LEFT JOIN 
    Comments c ON ps.PostId = c.PostId
LEFT JOIN 
    Users u ON c.UserId = u.Id
GROUP BY 
    ps.PostId, ps.Title, ps.UpVotes, ps.DownVotes, ps.CommentCount, ps.FavoriteCount, ps.Level
ORDER BY 
    (ps.UpVotes - ps.DownVotes) DESC
LIMIT 100;
