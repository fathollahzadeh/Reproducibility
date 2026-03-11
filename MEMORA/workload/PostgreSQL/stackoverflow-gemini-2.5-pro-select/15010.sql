WITH TopPosts AS
  (SELECT p.Id,
          p.Title,
          p.OwnerUserId,
          p.CreationDate,
          p.Score,
          p.ViewCount
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       u.DisplayName AS OwnerDisplayName,
       tp.CreationDate,
       tp.Score,
       tp.ViewCount,

  (SELECT COUNT(c.Id)
   FROM Comments c
   WHERE c.PostId = tp.Id) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY tp.CreationDate DESC;