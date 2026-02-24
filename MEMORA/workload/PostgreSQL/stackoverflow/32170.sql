WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
PostScore AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        ph.Depth
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostHierarchy ph ON ph.Id = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, ph.Depth, p.OwnerUserId
),
RecentEdits AS (
    SELECT 
        postId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        postId
)
SELECT 
    u.DisplayName,
    p.Title,
    ps.Score AS PostScore,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(re.EditCount, 0) AS EditCount,
    re.LastEditDate,
    ph.Depth
FROM 
    PostScore ps
JOIN 
    Posts p ON ps.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecentEdits re ON p.Id = re.postId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.Id
WHERE 
    u.Reputation > 1000 
    AND ps.Score > 0 
ORDER BY 
    ps.Score DESC, 
    ph.Depth ASC
LIMIT 100;