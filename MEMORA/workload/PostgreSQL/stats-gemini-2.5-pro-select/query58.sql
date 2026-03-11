 
 WITH post_counts AS
  (SELECT p.OwnerUserId,
          count(*) AS n
   FROM posts AS p
   JOIN postLinks AS pl ON p.Id = pl.RelatedPostId
   WHERE p.CommentCount BETWEEN 0 AND 13
   GROUP BY p.OwnerUserId),
     badge_counts AS
  (SELECT b.UserId,
          count(*) AS n
   FROM badges AS b
   WHERE b.Date <= '2014-09-09 10:24:35'::timestamp
   GROUP BY b.UserId),
     history_counts AS
  (SELECT ph.UserId,
          count(*) AS n
   FROM postHistory AS ph
   WHERE ph.PostHistoryTypeId = 5
     AND ph.CreationDate <= '2014-08-13 09:20:10'::timestamp
   GROUP BY ph.UserId),
     vote_counts AS
  (SELECT v.UserId,
          count(*) AS n
   FROM votes AS v
   WHERE v.CreationDate >= '2010-07-19 00:00:00'::timestamp
   GROUP BY v.UserId)
SELECT SUM(pc.n * bc.n * hc.n * vc.n)
FROM users AS u
JOIN post_counts AS pc ON u.Id = pc.OwnerUserId
JOIN badge_counts AS bc ON u.Id = bc.UserId
JOIN history_counts AS hc ON u.Id = hc.UserId
JOIN vote_counts AS vc ON u.Id = vc.UserId
WHERE u.Views >= 0
  AND u.DownVotes >= 0
  AND u.CreationDate BETWEEN '2010-08-04 16:59:53'::timestamp AND '2014-07-22 15:15:22'::timestamp;