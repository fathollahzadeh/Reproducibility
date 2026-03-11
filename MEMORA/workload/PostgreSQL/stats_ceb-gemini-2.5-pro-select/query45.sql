 
 WITH filtered_badges AS
  (SELECT UserId
   FROM badges
   WHERE Date >= '2010-07-19 19:39:10' :: timestamp
     AND Date <= '2014-09-05 18:37:48' :: timestamp)
SELECT COUNT(*)
FROM filtered_badges AS b
JOIN users AS u ON b.UserId = u.Id
JOIN postHistory AS ph ON u.Id = ph.UserId
JOIN votes AS v ON u.Id = v.UserId
WHERE u.Views = 5
  AND u.DownVotes >= 0
  AND u.UpVotes >= 0
  AND u.UpVotes <= 224
  AND u.CreationDate <= '2014-09-05 18:37:48' :: timestamp
  AND ph.PostHistoryTypeId = 2;