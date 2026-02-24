
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.CreationDate,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    p.Title AS QuestionTitle,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    MAX(COALESCE(b.Class, 0)) AS HighestBadgeClass,
    ph.Level AS QuestionLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostHierarchy ph
JOIN 
    Posts p ON p.Id = ph.PostId
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
LEFT JOIN 
    Votes v ON v.PostId = p.Id 
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag) 
WHERE 
    p.ViewCount > 1000 
GROUP BY 
    u.DisplayName, p.Title, ph.Level
HAVING 
    COUNT(DISTINCT a.Id) > 5 
ORDER BY 
    UpVotes DESC, QuestionLevel ASC;
