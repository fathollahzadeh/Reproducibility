
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(v.Id) AS VoteCount,
    COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS Downvotes,
    COALESCE(SUM(CASE WHEN vt.Name = 'BountyStart' THEN v.BountyAmount ELSE 0 END), 0) AS TotalBounty,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    VoteCount DESC, p.CreationDate DESC;
