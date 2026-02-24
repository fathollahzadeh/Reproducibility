
SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
    COALESCE(SUM(CASE WHEN ph.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalHistoryEntries,
    AVG(u.Reputation) AS AverageReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON TRIM(tag) = t.TagName
WHERE 
    u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, AverageReputation DESC
LIMIT 100;
