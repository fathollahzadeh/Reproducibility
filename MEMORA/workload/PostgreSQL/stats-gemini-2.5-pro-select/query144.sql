 
 
SELECT COUNT(*)
FROM users AS u,
     posts AS p,
     badges AS b,
     comments AS c,
     postHistory AS ph,
     votes AS v
WHERE u.Id = p.OwnerUserId
  AND p.Id = c.PostId
  AND p.Id = ph.PostId
  AND p.Id = v.PostId
  AND u.Id = b.UserId
  AND u.Reputation >= 1
  AND u.Reputation <= 642
  AND u.DownVotes >= 0
  AND p.AnswerCount >= 0
  AND p.CommentCount >= 0
  AND b.Date <= '2014-09-11 21:46:02' :: timestamp;