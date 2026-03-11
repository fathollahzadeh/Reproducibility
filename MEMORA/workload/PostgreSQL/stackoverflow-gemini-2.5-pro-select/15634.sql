WITH LatestPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT lp.Id,
       lp.Title,
       lp.CreationDate,
       u.DisplayName,
       lp.Score
FROM LatestPosts lp
JOIN Users u ON lp.OwnerUserId = u.Id
ORDER BY lp.CreationDate DESC;