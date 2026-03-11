 
 
SELECT COUNT(*)
FROM users AS u
JOIN badges AS b ON u.Id = b.UserId
JOIN posthistory AS ph ON u.Id = ph.UserId
JOIN votes AS v ON u.Id = v.UserId
WHERE u.Reputation <= 126
  AND u.Views <= 11
  AND u.CreationDate >= '2010-08-02 16:17:58'::timestamp
  AND u.CreationDate <= '2014-09-12 00:16:30'::timestamp
  AND b.Date <= '2014-09-03 16:13:12'::timestamp
  AND ph.PostHistoryTypeId = 1
  AND v.CreationDate <= '2014-09-12 00:16:30'::timestamp;