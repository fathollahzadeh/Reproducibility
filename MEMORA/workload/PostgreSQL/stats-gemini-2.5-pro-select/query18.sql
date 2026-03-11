 
 
SELECT COUNT(*)
FROM posts AS p
JOIN postLinks AS pl ON p.Id = pl.PostId
JOIN postHistory AS ph ON p.Id = ph.PostId
WHERE p.CreationDate >= '2010-07-19 20:08:37' :: timestamp
  AND ph.CreationDate >= '2010-07-20 00:30:00' :: timestamp;