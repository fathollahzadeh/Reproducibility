WITH TopPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT tp.Title,
       tp.CreationDate,
       u.DisplayName AS OwnerName,
       COUNT(c.Id) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN Comments c ON tp.Id = c.PostId
GROUP BY tp.Id,
         tp.Title,
         tp.CreationDate,
         u.DisplayName
ORDER BY tp.CreationDate DESC;