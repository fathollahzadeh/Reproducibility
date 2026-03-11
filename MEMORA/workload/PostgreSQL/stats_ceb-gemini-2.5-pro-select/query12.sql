 
 
SELECT COUNT(*)
FROM comments AS c
INNER JOIN users AS u ON c.UserId = u.Id
INNER JOIN postHistory AS ph ON c.UserId = ph.UserId
WHERE u.Reputation >= 1
  AND u.Reputation <= 487
  AND u.UpVotes <= 27
  AND u.CreationDate >= '2010-10-22 22:40:35'::timestamp
  AND u.CreationDate <= '2014-09-10 17:01:31'::timestamp;