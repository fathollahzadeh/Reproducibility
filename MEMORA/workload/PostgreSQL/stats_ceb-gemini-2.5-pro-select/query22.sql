 
 WITH qualifying_posts_per_user AS
  (SELECT p.OwnerUserId,
          COUNT(*) AS post_count
   FROM users u
   JOIN posts p ON u.Id = p.OwnerUserId
   WHERE u.CreationDate BETWEEN '2010-07-22 04:38:06'::timestamp AND '2014-09-08 15:55:02'::timestamp
     AND p.CommentCount BETWEEN 0 AND 12
   GROUP BY p.OwnerUserId)
SELECT SUM(q.post_count)
FROM qualifying_posts_per_user q
JOIN votes v ON q.OwnerUserId = v.UserId;