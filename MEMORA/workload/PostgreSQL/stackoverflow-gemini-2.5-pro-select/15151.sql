WITH TopPosts AS
  (SELECT p.Id,
          p.OwnerUserId,
          p.Title,
          p.CreationDate
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT u.DisplayName,
       tp.Title,
       tp.CreationDate,
       COALESCE(cc.CommentCount, 0) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN
  (SELECT c.PostId,
          COUNT(c.Id) AS CommentCount
   FROM Comments c
   WHERE c.PostId IN
       (SELECT Id
        FROM TopPosts)
   GROUP BY c.PostId) cc ON tp.Id = cc.PostId
ORDER BY tp.CreationDate DESC;