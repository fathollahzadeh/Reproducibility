WITH LimitedPosts AS MATERIALIZED
  (SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT lp.Id AS PostId,
       lp.Title,
       u.DisplayName AS OwnerDisplayName,
       lp.CreationDate,
       lp.Score,
       lp.ViewCount,
       lp.AnswerCount,
       lp.CommentCount
FROM LimitedPosts lp
JOIN Users u ON lp.OwnerUserId = u.Id
ORDER BY lp.CreationDate DESC;