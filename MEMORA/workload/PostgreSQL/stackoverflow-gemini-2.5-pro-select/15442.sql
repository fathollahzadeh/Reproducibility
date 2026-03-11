WITH TopPosts AS
  (SELECT p.Id,
          p.OwnerUserId,
          p.Title,
          p.CreationDate
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     RelevantCommentCounts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments c
   JOIN TopPosts tp ON c.PostId = tp.Id
   GROUP BY c.PostId)
SELECT u.DisplayName,
       tp.Title,
       tp.CreationDate,
       COALESCE(rcc.Cnt, 0) AS CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN RelevantCommentCounts rcc ON tp.Id = rcc.PostId
ORDER BY tp.CreationDate DESC;