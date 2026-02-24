
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(u.Reputation) AS AvgReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON TRIM(tag) = t.TagName
WHERE 
    u.LastAccessDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    PostCount DESC, AvgReputation DESC
LIMIT 100;
