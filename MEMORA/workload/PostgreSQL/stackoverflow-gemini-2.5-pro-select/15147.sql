WITH PostCandidates AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments c
   JOIN PostCandidates pc ON c.PostId = pc.Id
   GROUP BY c.PostId)
SELECT pc.Id AS PostId,
       pc.Title,
       pc.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM PostCandidates pc
JOIN Users u ON pc.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON pc.Id = cc.PostId
ORDER BY pc.CreationDate DESC;