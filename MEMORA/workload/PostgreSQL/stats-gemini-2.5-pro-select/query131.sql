 
 WITH comment_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM comments
   WHERE Score = 2
   GROUP BY UserId),
     post_counts AS
  (SELECT OwnerUserId,
          count(*) AS n
   FROM posts
   WHERE AnswerCount BETWEEN 0 AND 9
     AND CreationDate BETWEEN '2010-07-20 18:17:25'::timestamp AND '2014-08-26 12:57:22'::timestamp
   GROUP BY OwnerUserId),
     posthistory_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM postHistory
   WHERE CreationDate <= '2014-09-02 07:58:47'::timestamp
   GROUP BY UserId)
SELECT SUM(cc.n * pc.n * phc.n)
FROM users u
JOIN votes v ON u.Id = v.UserId
JOIN comment_counts cc ON u.Id = cc.UserId
JOIN post_counts pc ON u.Id = pc.OwnerUserId
JOIN posthistory_counts phc ON u.Id = phc.UserId
WHERE u.UpVotes <= 230
  AND u.CreationDate BETWEEN '2010-09-22 01:07:10'::timestamp AND '2014-08-15 05:52:23'::timestamp
  AND v.BountyAmount >= 0
  AND v.CreationDate >= '2010-05-19 00:00:00'::timestamp;