 
 
SELECT COUNT(*)
FROM comments AS c
INNER JOIN postLinks AS pl ON c.PostId = pl.PostId
INNER JOIN votes AS v ON c.PostId = v.PostId
INNER JOIN postHistory AS ph ON c.PostId = ph.PostId
WHERE ph.CreationDate >= '2011-05-07 21:47:19' :: timestamp
  AND ph.CreationDate <= '2014-09-10 13:19:54' :: timestamp;