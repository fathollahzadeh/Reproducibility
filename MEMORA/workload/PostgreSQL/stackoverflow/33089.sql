
WITH RECURSIVE RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.ParentId,
        r.Level + 1,
        p2.Title,
        p2.CreationDate,
        p2.LastActivityDate,
        p2.ViewCount,
        p2.Score
    FROM 
        Posts p2
    JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
    AVG(COALESCE(ph.ViewCount, 0)) AS AverageViews,
    AVG(COALESCE(ph.Score, 0)) AS AverageScore,
    STRING_AGG(DISTINCT tags.TagName, ', ') AS AssociatedTags,
    MAX(ph.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    RecursivePostHierarchy ph ON p.Id = ph.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(UNNEST(string_to_array(p.Tags, ','))) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = ph.PostId
    ) AS tags ON TRUE
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5 
ORDER BY 
    TotalUpVotes DESC, 
    LastPostDate DESC 
LIMIT 10;
