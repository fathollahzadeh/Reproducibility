WITH top_posts AS
  (SELECT p.OwnerUserId,
          p.Title,
          p.CreationDate,
          p.Score,
          p.ViewCount
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT u.DisplayName,
       tp.Title,
       tp.CreationDate,
       tp.Score,
       tp.ViewCount
FROM top_posts tp
JOIN Users u ON tp.OwnerUserId = u.Id;