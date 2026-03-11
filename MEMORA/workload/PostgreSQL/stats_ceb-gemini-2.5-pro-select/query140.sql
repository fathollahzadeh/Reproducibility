 
 WITH pl_counts AS
  (SELECT RelatedPostId,
          count(*) AS n
   FROM postLinks
   WHERE LinkTypeId = 1
     AND CreationDate BETWEEN '2011-02-16 20:04:50'::timestamp AND '2014-09-01 16:48:04'::timestamp
   GROUP BY RelatedPostId),
     v_counts AS
  (SELECT PostId,
          count(*) AS n
   FROM votes
   WHERE CreationDate BETWEEN '2010-07-19 00:00:00'::timestamp AND '2014-08-31 00:00:00'::timestamp
   GROUP BY PostId),
     ph_counts AS
  (SELECT PostId,
          count(*) AS n
   FROM postHistory
   GROUP BY PostId),
     b_user_counts AS
  (SELECT UserId,
          count(*) AS n
   FROM badges
   WHERE Date BETWEEN '2010-08-06 10:36:45'::timestamp AND '2014-09-12 07:19:35'::timestamp
   GROUP BY UserId),
     c_post_counts AS
  (SELECT c.PostId,
          sum(buc.n) AS n
   FROM comments AS c
   JOIN b_user_counts AS buc ON c.UserId = buc.UserId
   WHERE c.Score = 0
   GROUP BY c.PostId)
SELECT SUM(plc.n * vc.n * phc.n * cpc.n)
FROM posts AS p
JOIN pl_counts AS plc ON p.Id = plc.RelatedPostId
JOIN v_counts AS vc ON p.Id = vc.PostId
JOIN ph_counts AS phc ON p.Id = phc.PostId
JOIN c_post_counts AS cpc ON p.Id = cpc.PostId
WHERE p.ViewCount >= 0
  AND p.AnswerCount <= 5
  AND p.CommentCount <= 12
  AND p.FavoriteCount >= 0;