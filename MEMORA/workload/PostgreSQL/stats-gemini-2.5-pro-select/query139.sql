 
 WITH base_posts AS
  (SELECT p.Id
   FROM users AS u
   JOIN badges AS b ON u.Id = b.UserId
   JOIN posts AS p ON u.Id = p.OwnerUserId
   WHERE u.DownVotes >= 0
     AND b.Date BETWEEN '2010-08-04 08:50:31'::timestamp AND '2014-09-02 02:51:22'::timestamp
     AND p.Score BETWEEN -1 AND 14),
     link_counts AS
  (SELECT pl.RelatedPostId AS PostId,
          COUNT(*) AS ct
   FROM postLinks AS pl
   WHERE pl.CreationDate <= '2014-06-25 13:05:06'::timestamp
   GROUP BY pl.RelatedPostId),
     vote_counts AS
  (SELECT v.PostId,
          COUNT(*) AS ct
   FROM votes AS v
   WHERE v.CreationDate >= '2009-02-02 00:00:00'::timestamp
   GROUP BY v.PostId),
     comment_counts AS
  (SELECT c.PostId,
          COUNT(*) AS ct
   FROM comments AS c
   GROUP BY c.PostId)
SELECT SUM(lc.ct * vc.ct * cc.ct)
FROM base_posts bp
JOIN link_counts lc ON bp.Id = lc.PostId
JOIN vote_counts vc ON bp.Id = vc.PostId
JOIN comment_counts cc ON bp.Id = cc.PostId;