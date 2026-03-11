 
 
SELECT COUNT(*)
FROM users AS u
JOIN comments AS c ON c.UserId = u.Id
JOIN postHistory AS ph ON ph.UserId = u.Id
WHERE u.Reputation >= 1
  AND u.Reputation <= 7931
  AND u.Views <= 109
  AND u.DownVotes >= 0
  AND u.CreationDate <= '2014-09-12 13:12:56' :: timestamp;