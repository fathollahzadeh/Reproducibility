 
 WITH votes_count AS
  (SELECT PostId,
          COUNT(*) AS n_v
   FROM votes
   WHERE CreationDate <= '2014-09-12 00:00:00' :: timestamp
   GROUP BY PostId),
     comments_count AS
  (SELECT PostId,
          COUNT(*) AS n_c
   FROM comments
   GROUP BY PostId)
SELECT SUM(v_c_join.n_v * v_c_join.n_c * phc.n_ph)
FROM
  (SELECT vc.PostId,
          vc.n_v,
          cc.n_c
   FROM votes_count vc
   JOIN comments_count cc ON vc.PostId = cc.PostId) AS v_c_join
JOIN
  (SELECT PostId,
          COUNT(*) AS n_ph
   FROM postHistory
   GROUP BY PostId) AS phc ON v_c_join.PostId = phc.PostId;