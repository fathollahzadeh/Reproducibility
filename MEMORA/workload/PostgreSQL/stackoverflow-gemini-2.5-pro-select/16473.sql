
SELECT p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p.Score,
       p.ViewCount
FROM
  (SELECT Title,
          CreationDate,
          OwnerUserId,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) p
CROSS JOIN LATERAL
  (SELECT DisplayName
   FROM Users
   WHERE Id = p.OwnerUserId) u;