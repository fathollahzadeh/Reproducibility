WITH LimitedPosts AS
  (SELECT Id,
          Title,
          OwnerUserId,
          CreationDate,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM LimitedPosts)
   GROUP BY PostId)
SELECT lp.Id AS PostId,
       lp.Title,
       u.DisplayName AS OwnerDisplayName,
       lp.CreationDate,
       lp.Score,
       COALESCE(cc.Cnt, 0) AS CommentCount
FROM LimitedPosts lp
JOIN Users u ON lp.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON lp.Id = cc.PostId
ORDER BY lp.CreationDate DESC;