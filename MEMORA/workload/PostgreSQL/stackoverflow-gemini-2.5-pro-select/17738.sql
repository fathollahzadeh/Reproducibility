WITH TopPosts AS
  (SELECT p.OwnerUserId,
          p.Title,
          p.CreationDate,
          p.Score
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT u.DisplayName,
       tp.Title,
       tp.CreationDate,
       tp.Score
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY tp.CreationDate DESC;