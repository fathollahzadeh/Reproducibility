 
 
SELECT SUM(p.p_count * b.b_count * v.v_count)
FROM
  (SELECT Id
   FROM users
   WHERE Reputation >= 1
     AND DownVotes >= 0
     AND DownVotes <= 1) fu
JOIN
  (SELECT OwnerUserId,
          COUNT(*) AS p_count
   FROM posts
   WHERE PostTypeId = 1
     AND CommentCount >= 0
     AND CommentCount <= 15
   GROUP BY OwnerUserId) p ON fu.Id = p.OwnerUserId
JOIN
  (SELECT UserId,
          COUNT(*) AS b_count
   FROM badges
   GROUP BY UserId) b ON fu.Id = b.UserId
JOIN
  (SELECT UserId,
          COUNT(*) AS v_count
   FROM votes
   GROUP BY UserId) v ON fu.Id = v.UserId;