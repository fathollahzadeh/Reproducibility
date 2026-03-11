WITH FilteredPosts AS
  (SELECT *
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT fp.Id AS PostId,
       fp.Title,
       fp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       fp.ViewCount,
       fp.Score
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
ORDER BY fp.CreationDate DESC;