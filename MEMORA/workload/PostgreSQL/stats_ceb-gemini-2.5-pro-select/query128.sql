 
 
SELECT COUNT(p.Id)
FROM
  (SELECT *
   FROM posts
   WHERE Score <= 44
     AND FavoriteCount BETWEEN 0 AND 3
     AND CreationDate BETWEEN '2010-08-11 13:53:56'::timestamp AND '2014-09-03 11:52:36'::timestamp) AS p
INNER JOIN comments AS c ON p.Id = c.PostId
INNER JOIN postLinks AS pl ON p.Id = pl.PostId
INNER JOIN postHistory AS ph ON p.Id = ph.PostId
INNER JOIN votes AS v ON p.Id = v.PostId
WHERE c.CreationDate >= '2010-08-01 12:12:41' :: timestamp
  AND pl.LinkTypeId = 1
  AND pl.CreationDate <= '2014-08-11 17:26:31' :: timestamp
  AND ph.CreationDate >= '2010-09-20 19:11:45' :: timestamp
  AND v.CreationDate <= '2014-09-11 00:00:00' :: timestamp;