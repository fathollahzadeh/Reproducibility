
SELECT
  (SELECT DisplayName
   FROM Users u
   WHERE u.Id = p.OwnerUserId), p.Title,
                                p.CreationDate,
                                p.Score,
                                p.ViewCount
FROM Posts p
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;