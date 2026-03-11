WITH PostUsers AS
  (SELECT p.Id,
          p.Title,
          u.DisplayName,
          p.CreationDate,
          p.Score,
          p.ViewCount,
          p.PostTypeId
   FROM Posts p
   JOIN Users u ON p.OwnerUserId = u.Id)
SELECT Id AS PostId,
       Title,
       DisplayName AS OwnerDisplayName,
       CreationDate,
       Score,
       ViewCount
FROM PostUsers
WHERE PostTypeId = 1
ORDER BY CreationDate DESC
LIMIT 10;