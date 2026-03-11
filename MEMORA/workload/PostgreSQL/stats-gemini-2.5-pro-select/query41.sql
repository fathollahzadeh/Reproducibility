 
 SELECT COUNT(*)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN badges AS b ON u.Id = b.UserId
JOIN postlinks AS pl ON p.Id = pl.RelatedPostId
WHERE u.CreationDate BETWEEN '2010-08-19 17:31:36' :: timestamp AND '2014-08-06 07:23:12' :: timestamp
  AND u.Views <= 33
  AND u.DownVotes >= 0
  AND p.Score BETWEEN -1 AND 10
  AND p.AnswerCount <= 5
  AND p.CommentCount = 2
  AND b.Date <= '2014-09-10 22:50:06' :: timestamp
  AND pl.CreationDate <= '2014-08-17 01:23:50' :: timestamp
  AND p.FavoriteCount BETWEEN 0 AND 6;