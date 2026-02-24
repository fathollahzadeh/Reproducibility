SELECT u.DisplayName, p.Title, p.CreationDate, v.VoteTypeId
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN Votes v ON p.Id = v.PostId
WHERE v.VoteTypeId = 2 
ORDER BY p.CreationDate DESC
LIMIT 10;