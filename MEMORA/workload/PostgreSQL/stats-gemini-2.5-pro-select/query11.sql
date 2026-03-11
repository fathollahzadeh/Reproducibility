 
 
SELECT COUNT(*)
FROM users u
JOIN posts p ON u.Id = p.OwnerUserId
JOIN comments c ON u.Id = c.UserId
WHERE c.Score = 0
  AND p.Score BETWEEN 0 AND 15
  AND p.ViewCount BETWEEN 0 AND 3002
  AND p.AnswerCount <= 3
  AND p.CommentCount <= 10
  AND u.DownVotes <= 0
  AND u.UpVotes >= 0
  AND u.CreationDate BETWEEN '2010-08-23 16:21:10'::timestamp AND '2014-09-02 09:50:06'::timestamp;