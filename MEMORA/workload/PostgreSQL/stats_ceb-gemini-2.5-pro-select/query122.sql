 
 WITH ph_counts AS
  (SELECT UserId,
          count(*) AS ct
   FROM postHistory
   WHERE CreationDate BETWEEN '2010-07-27 18:08:19'::timestamp AND '2014-09-10 08:22:43'::timestamp
   GROUP BY UserId),
     p_counts AS
  (SELECT OwnerUserId,
          count(*) AS ct
   FROM posts
   WHERE PostTypeId = 2
   GROUP BY OwnerUserId),
     b_counts AS
  (SELECT UserId,
          count(*) AS ct
   FROM badges
   GROUP BY UserId)
SELECT sum(ph.ct * p.ct * b.ct)
FROM ph_counts AS ph
JOIN p_counts AS p ON ph.UserId = p.OwnerUserId
JOIN b_counts AS b ON ph.UserId = b.UserId;