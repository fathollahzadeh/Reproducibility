WITH FilteredPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT fp.Id AS PostId,
       fp.Title,
       fp.CreationDate,
       u.DisplayName AS OwnerDisplayName,

  (SELECT COUNT(*)
   FROM Comments c
   WHERE c.PostId = fp.Id) AS CommentCount,

  (SELECT COUNT(*)
   FROM Votes v
   WHERE v.PostId = fp.Id) AS VoteCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
ORDER BY fp.CreationDate DESC;