 
 WITH post_counts AS
  (SELECT OwnerUserId AS UserId,
          count(*) AS n
   FROM posts
   WHERE Score BETWEEN -1 AND 29
     AND CreationDate BETWEEN '2010-07-19 20:40:36'::timestamp AND '2014-09-10 20:52:30'::timestamp
   GROUP BY OwnerUserId),
     badge_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM badges
   WHERE Date <= '2014-08-25 19:05:46'::timestamp
   GROUP BY UserId)
SELECT SUM(pc.n * bc.n)
FROM users u
JOIN comments c ON u.Id = c.UserId
JOIN votes v ON u.Id = v.UserId
JOIN post_counts pc ON u.Id = pc.UserId
JOIN badge_counts bc ON u.Id = bc.UserId
WHERE u.DownVotes <= 11
  AND u.CreationDate BETWEEN '2010-07-31 17:32:56'::timestamp AND '2014-09-07 16:06:26'::timestamp
  AND c.Score = 1
  AND v.BountyAmount <= 50;