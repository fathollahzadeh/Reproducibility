WITH latest_posts AS
  (SELECT *
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT p.Id,
       p.Title,
       u.DisplayName,
       p.CreationDate,
       p.Score
FROM latest_posts p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;