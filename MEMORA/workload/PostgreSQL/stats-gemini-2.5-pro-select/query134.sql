 
 
SELECT COUNT(*)
FROM
  (SELECT UserId
   FROM comments
   WHERE Score = 0) AS c
JOIN users AS u ON c.UserId = u.Id
AND u.Views = 0
AND u.DownVotes BETWEEN 0 AND 60
JOIN posts AS p ON u.Id = p.OwnerUserId
AND p.Score >= -2
AND p.CommentCount BETWEEN 0 AND 12
AND p.FavoriteCount BETWEEN 0 AND 6
JOIN postHistory AS ph ON u.Id = ph.UserId
AND ph.CreationDate <= '2014-08-18 08:54:12' :: timestamp
JOIN badges AS b ON u.Id = b.UserId;