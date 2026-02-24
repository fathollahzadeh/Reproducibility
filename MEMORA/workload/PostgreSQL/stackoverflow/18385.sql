SELECT u.DisplayName AS UserName, 
       p.Title AS PostTitle, 
       p.CreationDate AS PostDate, 
       ph.Comment AS EditComment, 
       ph.CreationDate AS EditDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN PostHistory ph ON p.Id = ph.PostId
WHERE ph.PostHistoryTypeId IN (4, 5) 
ORDER BY p.CreationDate DESC
LIMIT 10;