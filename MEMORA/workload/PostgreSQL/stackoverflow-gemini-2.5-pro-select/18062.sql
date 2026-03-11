WITH FilteredPosts AS
  (SELECT Title,
          OwnerUserId,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT fp.Title,
       u.DisplayName AS OWNER,
       fp.CreationDate,
       fp.Score,
       fp.ViewCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
ORDER BY fp.CreationDate DESC;