WITH TopPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.Score,
          u.DisplayName
   FROM Posts p
   JOIN Users u ON p.OwnerUserId = u.Id
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       tp.CreationDate,
       tp.DisplayName AS OwnerDisplayName,
       tp.Score,
       COUNT(c.Id) AS CommentCount
FROM TopPosts tp
LEFT JOIN Comments c ON tp.Id = c.PostId
GROUP BY tp.Id,
         tp.Title,
         tp.CreationDate,
         tp.DisplayName,
         tp.Score
ORDER BY tp.CreationDate DESC;