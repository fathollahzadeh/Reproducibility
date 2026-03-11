 
 WITH comment_counts AS
  (SELECT UserId,
          COUNT(*) AS cnt
   FROM comments
   WHERE CreationDate BETWEEN '2010-07-31 05:18:59' :: timestamp AND '2014-09-12 07:59:13' :: timestamp
   GROUP BY UserId),
     post_counts AS
  (SELECT OwnerUserId,
          COUNT(*) AS cnt
   FROM posts
   WHERE Score >= -2
     AND ViewCount BETWEEN 0 AND 18281
   GROUP BY OwnerUserId),
     history_counts AS
  (SELECT UserId,
          COUNT(*) AS cnt
   FROM postHistory
   WHERE PostHistoryTypeId = 2
   GROUP BY UserId),
     badge_counts AS
  (SELECT UserId,
          COUNT(*) AS cnt
   FROM badges
   WHERE Date >= '2010-10-20 08:33:44' :: timestamp
   GROUP BY UserId)
SELECT SUM(cc.cnt * pc.cnt * hc.cnt * bc.cnt)
FROM users u
JOIN comment_counts cc ON u.Id = cc.UserId
JOIN post_counts pc ON u.Id = pc.OwnerUserId
JOIN history_counts hc ON u.Id = hc.UserId
JOIN badge_counts bc ON u.Id = bc.UserId
WHERE u.Views BETWEEN 0 AND 75;