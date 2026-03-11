
SELECT p.Id AS PostId,
       p.Title,

  (SELECT u.DisplayName
   FROM Users u
   WHERE u.Id = p.OwnerUserId) AS Author,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM Posts p
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;