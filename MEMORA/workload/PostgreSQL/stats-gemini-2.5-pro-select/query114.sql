 
 
SELECT COUNT(*)
FROM users AS u
INNER JOIN badges AS b ON u.Id = b.UserId
INNER JOIN postHistory AS ph ON u.Id = ph.UserId
INNER JOIN comments AS c ON u.Id = c.UserId
WHERE u.Views >= 0
  AND u.DownVotes >= 0
  AND u.UpVotes BETWEEN 0 AND 62
  AND u.CreationDate BETWEEN '2010-07-27 17:10:30' :: timestamp AND '2014-07-31 18:48:36' :: timestamp
  AND b.Date <= '2014-09-02 23:33:16' :: timestamp
  AND ph.PostHistoryTypeId = 2
  AND ph.CreationDate <= '2014-08-01 13:56:22' :: timestamp;