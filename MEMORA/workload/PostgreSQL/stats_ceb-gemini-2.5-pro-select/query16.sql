 
 WITH filtered_users AS
  (SELECT Id
   FROM users
   WHERE DownVotes >= 0
     AND UpVotes >= 0
     AND UpVotes <= 17
     AND CreationDate >= '2010-08-06 07:03:05' :: timestamp
     AND CreationDate <= '2014-09-08 04:18:44' :: timestamp)
SELECT COUNT(*)
FROM comments AS c
JOIN badges AS b ON c.UserId = b.UserId
JOIN filtered_users AS u ON c.UserId = u.Id
WHERE c.Score = 0
  AND b.Date >= '2010-07-19 20:54:06' :: timestamp;