 
 WITH user_post_counts AS
  (SELECT OwnerUserId,
          COUNT(*) AS post_count
   FROM posts
   WHERE AnswerCount BETWEEN 0 AND 4
     AND CommentCount BETWEEN 0 AND 11
     AND CreationDate BETWEEN '2010-07-26 09:46:48'::timestamp AND '2014-09-13 10:09:50'::timestamp
   GROUP BY OwnerUserId)
SELECT SUM(upc.post_count)
FROM users AS u
JOIN comments AS c ON u.Id = c.UserId
JOIN user_post_counts AS upc ON u.Id = upc.OwnerUserId
WHERE u.Reputation >= 1
  AND u.CreationDate BETWEEN '2010-08-03 19:42:40'::timestamp AND '2014-09-12 02:20:03'::timestamp
  AND c.CreationDate >= '2010-07-27 17:46:38'::timestamp;