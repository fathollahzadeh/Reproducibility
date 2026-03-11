
SELECT p.Id AS PostId,
       p.Title,
       u.DisplayName AS Author,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM Posts p,
     Users u
WHERE p.OwnerUserId = u.Id
  AND p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;