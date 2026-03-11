WITH posts_subset AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     comment_counts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS cnt
   FROM Comments c
   JOIN posts_subset ps ON c.PostId = ps.Id
   GROUP BY c.PostId)
SELECT ps.Id AS PostId,
       ps.Title,
       ps.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.cnt, 0) AS CommentCount
FROM posts_subset ps
JOIN Users u ON ps.OwnerUserId = u.Id
LEFT JOIN comment_counts cc ON ps.Id = cc.PostId
ORDER BY ps.CreationDate DESC;