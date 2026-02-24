
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS OwnerUserId,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    AVG(p.Score) AS AverageScore,
    MAX(p.Score) AS MaximumScore,
    MIN(p.Score) AS MinimumScore,
    p.ViewCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100;
