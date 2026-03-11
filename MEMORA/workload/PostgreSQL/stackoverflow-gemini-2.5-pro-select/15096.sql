WITH TopPosts AS
  (SELECT Id,
          Title,
          OwnerUserId,
          CreationDate
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10
   OFFSET 0)
SELECT p.Id,
       p.Title,
       u.DisplayName,
       p.CreationDate
FROM TopPosts p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;