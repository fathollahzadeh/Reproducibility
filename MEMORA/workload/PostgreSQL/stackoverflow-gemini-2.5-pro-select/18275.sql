WITH FilteredPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT fp.Title,
       fp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       cc.CommentCount,
       vc.VoteCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
CROSS JOIN LATERAL
  (SELECT COUNT(c.Id) AS CommentCount
   FROM Comments c
   WHERE c.PostId = fp.Id) cc
CROSS JOIN LATERAL
  (SELECT COUNT(v.Id) AS VoteCount
   FROM Votes v
   WHERE v.PostId = fp.Id) vc
ORDER BY fp.CreationDate DESC;