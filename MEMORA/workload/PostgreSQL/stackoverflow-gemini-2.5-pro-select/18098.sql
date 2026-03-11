WITH FilteredPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM FilteredPosts)
   GROUP BY PostId),
     VoteCounts AS
  (SELECT PostId,
          COUNT(Id) AS Cnt
   FROM Votes
   WHERE PostId IN
       (SELECT Id
        FROM FilteredPosts)
   GROUP BY PostId)
SELECT fp.Id AS PostId,
       fp.Title,
       fp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.Cnt, 0) AS CommentCount,
       COALESCE(vc.Cnt, 0) AS VoteCount
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON fp.Id = cc.PostId
LEFT JOIN VoteCounts vc ON fp.Id = vc.PostId
ORDER BY fp.CreationDate DESC;