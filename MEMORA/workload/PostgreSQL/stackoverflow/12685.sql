
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty, 
    COUNT(b.Id) AS BadgeCount, 
    u.Reputation AS OwnerReputation,
    DATE_TRUNC('day', p.CreationDate) AS CreationDate
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN Comments c ON c.PostId = p.Id
LEFT JOIN Votes v ON v.PostId = p.Id
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Badges b ON b.UserId = u.Id
WHERE p.CreationDate >= '2023-01-01' 
GROUP BY p.Id, p.Title, pt.Name, u.Reputation, p.CreationDate
ORDER BY p.CreationDate DESC;
