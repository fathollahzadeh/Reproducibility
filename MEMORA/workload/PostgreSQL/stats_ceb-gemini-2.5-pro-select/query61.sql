 
 
SELECT SUM(c.c_count * pl.pl_count * v.v_count * b.b_count)
FROM posts p
JOIN users u ON p.OwnerUserId = u.Id,
                LATERAL
  (SELECT count(*) AS c_count
   FROM comments c
   WHERE c.PostId = p.Id
     AND c.CreationDate >= '2010-08-06 12:21:39' :: timestamp
     AND c.CreationDate <= '2014-09-11 20:55:34' :: timestamp) c,
                        LATERAL
  (SELECT count(*) AS pl_count
   FROM postLinks pl
   WHERE pl.RelatedPostId = p.Id
     AND pl.LinkTypeId = 1
     AND pl.CreationDate >= '2011-03-11 18:50:29' :: timestamp) pl,
                                LATERAL
  (SELECT count(*) AS v_count
   FROM votes v
   WHERE v.PostId = p.Id
     AND v.VoteTypeId = 2
     AND v.CreationDate <= '2014-09-11 00:00:00' :: timestamp) v,
                                        LATERAL
  (SELECT count(*) AS b_count
   FROM badges b
   WHERE b.UserId = u.Id) b
WHERE p.Score >= 0
  AND p.Score <= 13
  AND p.FavoriteCount >= 0
  AND u.Reputation >= 1
  AND u.CreationDate >= '2011-02-17 03:42:02' :: timestamp
  AND u.CreationDate <= '2014-09-01 10:54:39' :: timestamp
  AND c.c_count > 0
  AND pl.pl_count > 0
  AND v.v_count > 0
  AND b.b_count > 0;