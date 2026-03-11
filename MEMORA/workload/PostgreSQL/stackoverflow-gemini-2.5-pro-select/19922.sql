WITH LimitedPosts AS
  (SELECT Title,
          CreationDate,
          OwnerUserId,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT lp.Title,
       lp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       lp.Score,
       lp.ViewCount
FROM LimitedPosts lp
JOIN Users u ON lp.OwnerUserId = u.Id
ORDER BY lp.CreationDate DESC;