WITH TopPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     PostCommentCounts AS
  (SELECT tp.Id,
          tp.Title,
          tp.CreationDate,
          tp.OwnerUserId,
          COUNT(c.Id) AS CommentCount
   FROM TopPosts tp
   LEFT JOIN Comments c ON tp.Id = c.PostId
   GROUP BY tp.Id,
            tp.Title,
            tp.CreationDate,
            tp.OwnerUserId)
SELECT pcc.Title,
       pcc.CreationDate,
       u.DisplayName,
       pcc.CommentCount
FROM PostCommentCounts pcc
JOIN Users u ON pcc.OwnerUserId = u.Id
ORDER BY pcc.CreationDate DESC;