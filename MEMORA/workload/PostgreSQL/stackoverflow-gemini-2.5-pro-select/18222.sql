WITH AllData AS
  (SELECT u.DisplayName,
          p.Title,
          p.CreationDate,
          p.Score,
          p.ViewCount,
          p.PostTypeId
   FROM Posts p
   JOIN Users u ON p.OwnerUserId = u.Id)
SELECT DisplayName,
       Title,
       CreationDate,
       Score,
       ViewCount
FROM AllData
WHERE PostTypeId = 1
ORDER BY Score DESC
LIMIT 10;