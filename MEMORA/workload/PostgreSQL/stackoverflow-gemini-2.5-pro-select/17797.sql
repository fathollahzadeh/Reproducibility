WITH TopPostIds AS
  (SELECT Id,
          OwnerUserId,
          CreationDate
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT p.Id AS PostId,
       p.Title,
       u.DisplayName AS OwnerDisplayName,
       tpi.CreationDate,
       p.Score
FROM Posts p
JOIN TopPostIds tpi ON p.Id = tpi.Id
JOIN Users u ON tpi.OwnerUserId = u.Id
ORDER BY tpi.CreationDate DESC;