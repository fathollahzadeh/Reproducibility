 
 
SELECT COUNT(*)
FROM users AS u
INNER JOIN posts AS p ON u.Id = p.OwnerUserId
INNER JOIN badges AS b ON u.Id = b.UserId
INNER JOIN comments AS c ON u.Id = c.UserId
INNER JOIN postHistory AS ph ON u.Id = ph.UserId
WHERE u.Views <= 233
  AND u.DownVotes <= 2
  AND u.CreationDate >= '2010-09-16 16:00:55'::timestamp
  AND u.CreationDate <= '2014-08-24 21:12:02'::timestamp
  AND p.PostTypeId = 1
  AND p.Score <= 35
  AND p.AnswerCount = 1
  AND p.CommentCount <= 17
  AND p.FavoriteCount >= 0
  AND b.Date >= '2010-07-27 17:58:45'::timestamp
  AND b.Date <= '2014-09-06 17:33:22'::timestamp;