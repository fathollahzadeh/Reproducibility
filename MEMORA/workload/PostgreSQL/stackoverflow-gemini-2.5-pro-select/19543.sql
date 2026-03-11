
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS Author,
       COUNT(c.Id) AS CommentCount
FROM
  (SELECT *
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id,
         p.Title,
         p.CreationDate,
         u.DisplayName
ORDER BY p.CreationDate DESC;