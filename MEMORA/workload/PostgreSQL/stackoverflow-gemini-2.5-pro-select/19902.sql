
SELECT p.Id AS PostId,
       p.Title,
       u.DisplayName AS OwnerDisplayName,
       p.CreationDate,
       p.Score,
       p.ViewCount,
       p.AnswerCount,
       p.CommentCount
FROM
  (SELECT Id
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS top_p
JOIN LATERAL
  (SELECT *
   FROM Posts
   WHERE Id = top_p.Id) p ON TRUE
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;