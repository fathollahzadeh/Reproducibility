
SELECT 
    u.DisplayName AS User_Name,
    COUNT(DISTINCT p.Id) AS Total_Posts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Total_Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Total_Answers,
    AVG(u.Reputation) AS Avg_Reputation,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS Total_Gold_Badges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS Total_Silver_Badges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS Total_Bronze_Badges,
    MAX(p.CreationDate) AS Last_Post_Date,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Associated_Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON true
LEFT JOIN 
    Tags t ON tag = t.TagName
WHERE 
    u.CreationDate > DATE '2024-10-01' - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    Total_Posts DESC, Avg_Reputation DESC
LIMIT 10;
