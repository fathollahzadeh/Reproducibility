 
 WITH post_counts AS
  (SELECT p.OwnerUserId,
          count(*) AS cnt
   FROM posts AS p
   WHERE p.Score >= 0
   GROUP BY p.OwnerUserId),
     history_counts AS
  (SELECT ph.UserId,
          count(*) AS cnt
   FROM postHistory AS ph
   WHERE ph.CreationDate >= '2010-07-19 19:52:31'::timestamp
   GROUP BY ph.UserId),
     badge_counts AS
  (SELECT b.UserId,
          count(*) AS cnt
   FROM badges AS b
   GROUP BY b.UserId)
SELECT sum(pc.cnt * hc.cnt * bc.cnt)
FROM
  (SELECT u.Id
   FROM users AS u
   WHERE u.CreationDate BETWEEN '2010-07-27 02:56:06'::timestamp AND '2014-09-10 10:44:00'::timestamp) AS u
JOIN post_counts AS pc ON u.Id = pc.OwnerUserId
JOIN history_counts AS hc ON u.Id = hc.UserId
JOIN badge_counts AS bc ON u.Id = bc.UserId;