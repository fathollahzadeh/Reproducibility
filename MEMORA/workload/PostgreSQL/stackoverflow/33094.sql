WITH RECURSIVE UserPostHierarchy AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        1 AS PostLevel
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000  
    UNION ALL
    SELECT 
        u.Id,
        u.DisplayName,
        p.Id,
        p.Title,
        p.CreationDate,
        ph.PostLevel + 1
    FROM 
        UserPostHierarchy ph
    JOIN 
        Posts p ON ph.PostId = p.ParentId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    uph.UserId,
    uph.DisplayName,
    STRING_AGG(uph.Title, '; ') AS PostTitles,
    COUNT(uph.PostId) AS TotalPosts,
    MAX(uph.CreationDate) AS LastPostDate,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN ph.PostLevel = 2 THEN 1 ELSE 0 END) AS Level2Posts
FROM 
    UserPostHierarchy uph
LEFT JOIN 
    Posts p ON uph.PostId = p.Id
LEFT JOIN 
    UserPostHierarchy ph ON ph.UserId = uph.UserId
GROUP BY 
    uph.UserId, uph.DisplayName
HAVING 
    COUNT(uph.PostId) > 5 
ORDER BY 
    LastPostDate DESC
LIMIT 10;