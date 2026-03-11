 
 WITH comments_agg AS
  (SELECT UserId,
          count(*) AS comment_count
   FROM comments
   GROUP BY UserId),
     votes_agg AS
  (SELECT UserId,
          count(*) AS vote_count
   FROM votes
   WHERE CreationDate <= '2014-09-11 00:00:00'
   GROUP BY UserId)
SELECT sum(c.comment_count * v.vote_count)
FROM users AS u
JOIN comments_agg AS c ON u.id = c.UserId
JOIN votes_agg AS v ON u.id = v.UserId
WHERE u.CreationDate BETWEEN '2010-07-19 20:11:48'::timestamp AND '2014-07-09 20:37:10'::timestamp;