 
 WITH post_counts AS
  (SELECT OwnerUserId,
          COUNT(*) AS p_count
   FROM posts
   WHERE Score <= 52
     AND AnswerCount >= 0
   GROUP BY OwnerUserId),
     vote_counts AS
  (SELECT UserId,
          COUNT(*) AS v_count
   FROM votes
   WHERE CreationDate >= '2010-07-20 00:00:00'::timestamp
   GROUP BY UserId),
     user_comment_counts AS
  (SELECT u.Id,
          COUNT(c.Id) AS c_count
   FROM users u
   JOIN comments c ON u.Id = c.UserId
   WHERE u.UpVotes >= 0
     AND u.CreationDate BETWEEN '2010-10-05 05:52:35'::timestamp AND '2014-09-08 15:55:02'::timestamp
   GROUP BY u.Id)
SELECT SUM(pc.p_count * vc.v_count * ucc.c_count)
FROM user_comment_counts ucc
JOIN post_counts pc ON ucc.Id = pc.OwnerUserId
JOIN vote_counts vc ON ucc.Id = vc.UserId;