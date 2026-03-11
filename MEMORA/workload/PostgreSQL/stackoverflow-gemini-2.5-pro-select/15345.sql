WITH FilteredPosts AS
  (SELECT Id,
          OwnerUserId,
          Title,
          CreationDate,
          Score
   FROM Posts
   WHERE PostTypeId = 1),
     CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   GROUP BY PostId)
SELECT fp.Id AS PostId,
       fp.Title,
       fp.CreationDate,
       fp.Score,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON fp.Id = cc.PostId
ORDER BY fp.CreationDate DESC
LIMIT 10;