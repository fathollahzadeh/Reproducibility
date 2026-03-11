 
 
SELECT COUNT(*)
FROM users AS u
JOIN comments AS c ON c.UserId = u.Id
JOIN postHistory AS ph ON ph.UserId = u.Id
JOIN votes AS v ON v.UserId = u.Id
WHERE c.CreationDate <= '2014-08-28 07:25:55'::timestamp
  AND ph.PostHistoryTypeId = 2
  AND u.Reputation >= 1
  AND u.Views >= 0
  AND u.DownVotes >= 0
  AND u.UpVotes BETWEEN 0 AND 15
  AND u.CreationDate BETWEEN '2010-09-03 11:45:16'::timestamp AND '2014-08-18 17:19:53'::timestamp;