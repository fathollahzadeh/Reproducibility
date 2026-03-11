 
 WITH user_post_counts AS
  (SELECT p.OwnerUserId AS UserId,
          COUNT(*) AS PostCount
   FROM posts AS p
   WHERE p.Score >= 0
   GROUP BY p.OwnerUserId),
     user_history_counts AS
  (SELECT ph.UserId,
          COUNT(*) AS HistoryCount
   FROM posthistory AS ph
   WHERE ph.CreationDate >= '2010-08-21 05:30:40' :: timestamp
   GROUP BY ph.UserId)
SELECT COALESCE(SUM(upc.PostCount * uhc.HistoryCount), 0)
FROM users AS u
JOIN user_post_counts AS upc ON u.Id = upc.UserId
JOIN user_history_counts AS uhc ON u.Id = uhc.UserId
WHERE u.Reputation >= 1
  AND u.UpVotes <= 198
  AND u.CreationDate >= '2010-07-19 20:49:05' :: timestamp;