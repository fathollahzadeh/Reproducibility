 
 
SELECT SUM(pl.n * c.n * ph.n * v.n)
FROM
  (SELECT PostId,
          count(*) AS n
   FROM postLinks
   WHERE CreationDate BETWEEN '2011-03-22 06:18:34'::timestamp AND '2014-08-22 20:04:25'::timestamp
   GROUP BY PostId) AS pl,
     LATERAL
  (SELECT count(*) AS n
   FROM comments
   WHERE PostId = pl.PostId
     AND Score = 0) AS c,
             LATERAL
  (SELECT count(*) AS n
   FROM postHistory
   WHERE PostId = pl.PostId) AS ph,
                     LATERAL
  (SELECT count(*) AS n
   FROM votes
   WHERE PostId = pl.PostId) AS v
WHERE c.n > 0
  AND ph.n > 0
  AND v.n > 0;