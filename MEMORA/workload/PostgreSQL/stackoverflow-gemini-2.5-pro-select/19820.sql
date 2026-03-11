WITH CommentCounts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments c
   GROUP BY c.PostId),
     RankedPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId,
          COALESCE(cc.Cnt, 0) AS CommentCount
   FROM Posts p
   LEFT JOIN CommentCounts cc ON p.Id = cc.PostId
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT rp.Title,
       rp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       rp.CommentCount
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
ORDER BY rp.CreationDate DESC;