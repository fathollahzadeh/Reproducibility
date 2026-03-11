WITH TopPosts AS
  (SELECT p.Id,
          p.Title,
          p.OwnerUserId,
          p.CreationDate,
          p.Score
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       u.DisplayName AS OwnerDisplayName,
       tp.CreationDate,
       tp.Score,
       COUNT(c.Id) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN Comments c ON tp.Id = c.PostId
GROUP BY tp.Id,
         tp.Title,
         u.DisplayName,
         tp.CreationDate,
         tp.Score
ORDER BY tp.CreationDate DESC;