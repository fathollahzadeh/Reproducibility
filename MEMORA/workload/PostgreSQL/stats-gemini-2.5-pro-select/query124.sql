 
 
SELECT COUNT(*)
FROM users AS u
INNER JOIN badges AS b ON u.Id = b.UserId
INNER JOIN votes AS v ON u.Id = v.UserId
INNER JOIN postHistory AS ph ON u.Id = ph.UserId
WHERE u.DownVotes >= 0
  AND u.DownVotes <= 3
  AND u.UpVotes >= 0
  AND u.UpVotes <= 71
  AND b.Date >= '2010-07-19 21:54:06' :: timestamp
  AND v.CreationDate <= '2014-09-10 00:00:00' :: timestamp;