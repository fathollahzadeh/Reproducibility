
SELECT u.DisplayName,
       p.Title,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY Score DESC
   LIMIT 10) AS p,
     LATERAL
  (SELECT DisplayName
   FROM Users
   WHERE Id = p.OwnerUserId) AS u;