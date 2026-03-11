 
 
SELECT COUNT(*)
FROM
  (SELECT PostId
   FROM comments
   WHERE Score = 0) AS c
JOIN posts AS p ON c.PostId = p.Id
JOIN
  (SELECT PostId
   FROM postLinks
   WHERE CreationDate BETWEEN '2011-11-21 22:39:41'::timestamp AND '2014-09-01 16:29:56'::timestamp) AS pl ON p.Id = pl.PostId
JOIN
  (SELECT PostId
   FROM votes
   WHERE CreationDate BETWEEN '2010-07-22 00:00:00'::timestamp AND '2014-09-14 00:00:00'::timestamp) AS v ON p.Id = v.PostId
JOIN postHistory AS ph ON p.Id = ph.PostId;