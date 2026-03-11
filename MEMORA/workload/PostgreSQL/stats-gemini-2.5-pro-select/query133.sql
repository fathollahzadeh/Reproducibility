 
 
SELECT COUNT(*)
FROM users AS u
INNER JOIN comments AS c ON u.Id = c.UserId
INNER JOIN postHistory AS ph ON u.Id = ph.UserId
INNER JOIN badges AS b ON u.Id = b.UserId
INNER JOIN votes AS v ON u.Id = v.UserId
WHERE b.Date >= '2010-09-26 12:17:14' :: timestamp
  AND v.BountyAmount >= 0
  AND v.CreationDate >= '2010-07-20 00:00:00' :: timestamp
  AND v.CreationDate <= '2014-09-11 00:00:00' :: timestamp
  AND u.DownVotes >= 0
  AND u.DownVotes <= 0
  AND u.UpVotes >= 0
  AND u.UpVotes <= 31
  AND u.CreationDate <= '2014-08-06 20:38:52' :: timestamp;