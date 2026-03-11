 
 
SELECT COUNT(*)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
JOIN badges AS b ON u.Id = b.UserId
JOIN postHistory AS ph ON u.Id = ph.UserId
JOIN votes AS v ON u.Id = v.UserId
WHERE u.Reputation >= 1
  AND u.DownVotes BETWEEN 0 AND 0
  AND u.UpVotes <= 439
  AND u.CreationDate <= '2014-08-07 11:18:45'::timestamp
  AND p.AnswerCount >= 0
  AND p.FavoriteCount >= 0
  AND pl.LinkTypeId = 1
  AND ph.PostHistoryTypeId = 2
  AND v.CreationDate >= '2010-07-20 00:00:00'::timestamp;