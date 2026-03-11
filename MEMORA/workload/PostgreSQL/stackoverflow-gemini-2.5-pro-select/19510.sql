WITH TopPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId,
          Score,
          ViewCount,
          AnswerCount,
          CommentCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       tp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       tp.Score,
       tp.ViewCount,
       tp.AnswerCount,
       tp.CommentCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id;