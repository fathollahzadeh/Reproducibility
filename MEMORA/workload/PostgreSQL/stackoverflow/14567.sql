SELECT p.Title, p.CreationDate, COUNT(c.Id) AS CommentCount, 
       COUNT(DISTINCT v.Id) AS VoteCount, 
       COUNT(DISTINCT b.Id) AS BadgeCount, 
       COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY p.Title, p.CreationDate
ORDER BY p.CreationDate DESC;