
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    u.Reputation,
    u.CreationDate AS AccountCreationDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS t(TagName) ON TRUE
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    TotalPosts DESC, LastPostDate DESC
LIMIT 50;
