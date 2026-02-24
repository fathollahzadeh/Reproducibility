
SELECT p.Id AS PostId, 
       p.Title, 
       u.DisplayName AS OwnerDisplayName, 
       CASE 
           WHEN p.PostTypeId = 1 THEN 'Question' 
           WHEN p.PostTypeId = 2 THEN 'Answer' 
           ELSE 'Other' 
       END AS PostType, 
       p.CreationDate, 
       p.ViewCount, 
       COUNT(c.Id) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount
ORDER BY p.CreationDate DESC
LIMIT 10;
