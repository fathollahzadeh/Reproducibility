 
 WITH user_comments AS
  (SELECT c.UserId,
          COUNT(*) AS comment_count
   FROM comments AS c
   JOIN users AS u ON c.UserId = u.Id
   WHERE c.CreationDate BETWEEN '2010-07-27 15:46:34'::timestamp AND '2014-09-12 08:15:14'::timestamp
     AND u.CreationDate <= '2014-09-03 01:06:41'::timestamp
   GROUP BY c.UserId),
     user_votes AS
  (SELECT UserId,
          COUNT(*) AS vote_count
   FROM votes
   WHERE CreationDate BETWEEN '2010-07-19 00:00:00'::timestamp AND '2014-09-10 00:00:00'::timestamp
   GROUP BY UserId)
SELECT SUM(c.comment_count * v.vote_count)
FROM user_comments AS c
JOIN user_votes AS v ON c.UserId = v.UserId;