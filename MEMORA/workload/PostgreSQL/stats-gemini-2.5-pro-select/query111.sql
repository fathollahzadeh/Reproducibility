 
 
SELECT COUNT(*)
FROM posts AS p
INNER JOIN comments AS c ON c.PostId = p.Id
INNER JOIN postLinks AS pl ON pl.PostId = p.Id
INNER JOIN postHistory AS ph ON ph.PostId = p.Id
INNER JOIN votes AS v ON v.PostId = p.Id
WHERE pl.LinkTypeId = 1
  AND pl.CreationDate >= '2010-10-19 15:02:42'::timestamp
  AND ph.CreationDate <= '2014-06-18 17:14:07'::timestamp
  AND v.CreationDate >= '2010-07-20 00:00:00'::timestamp;