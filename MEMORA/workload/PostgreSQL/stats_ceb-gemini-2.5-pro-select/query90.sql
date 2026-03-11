 
 WITH user_history_counts AS
  (SELECT UserId,
          COUNT(*) AS HistoryCount
   FROM postHistory
   WHERE CreationDate >= '2011-05-20 18:43:03'::timestamp
   GROUP BY UserId)
SELECT SUM(uhc.HistoryCount)
FROM users u
JOIN posts p ON u.Id = p.OwnerUserId
JOIN user_history_counts uhc ON u.Id = uhc.UserId
WHERE u.CreationDate BETWEEN '2010-11-27 21:46:49'::timestamp AND '2014-08-18 13:00:22'::timestamp
  AND u.Views >= 0
  AND u.UpVotes >= 0
  AND p.FavoriteCount <= 5;