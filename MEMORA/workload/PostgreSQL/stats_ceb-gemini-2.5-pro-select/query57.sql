 
 
SELECT COUNT(*)
FROM users AS u
JOIN posts AS p ON u.Id = p.OwnerUserId
JOIN tags AS t ON p.Id = t.ExcerptPostId
JOIN votes AS v ON u.Id = v.UserId
JOIN badges AS b ON u.Id = b.UserId
WHERE u.Views >= 0
  AND u.Views <= 515
  AND u.UpVotes >= 0
  AND u.CreationDate <= '2014-09-07 13:46:41' :: timestamp
  AND v.BountyAmount >= 0
  AND v.BountyAmount <= 200
  AND b.Date <= '2014-09-12 12:56:22' :: timestamp;