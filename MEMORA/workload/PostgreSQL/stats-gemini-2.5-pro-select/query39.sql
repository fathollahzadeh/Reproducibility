 
 WITH user_filtered AS
  (SELECT id
   FROM users
   WHERE Reputation >= 1
     AND Reputation <= 356
     AND DownVotes <= 34
     AND CreationDate >= '2010-07-19 21:29:29'::timestamp
     AND CreationDate <= '2014-08-20 14:31:46'::timestamp),
     comment_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM comments
   WHERE Score = 0
     AND CreationDate >= '2010-07-20 10:52:57'::timestamp
   GROUP BY UserId),
     ph_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM postHistory
   WHERE PostHistoryTypeId = 5
     AND CreationDate >= '2011-01-31 15:35:37'::timestamp
   GROUP BY UserId),
     badge_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM badges
   GROUP BY UserId)
SELECT sum(cc.n * phc.n * bc.n)
FROM user_filtered u
JOIN comment_counts cc ON u.id = cc.UserId
JOIN ph_counts phc ON u.id = phc.UserId
JOIN badge_counts bc ON u.id = bc.UserId;