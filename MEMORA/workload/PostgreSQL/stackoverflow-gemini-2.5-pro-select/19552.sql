WITH LimitedPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts AS p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT c.PostId,
          COUNT(c.Id) AS Cnt
   FROM Comments AS c
   JOIN LimitedPosts AS lp ON c.PostId = lp.Id
   GROUP BY c.PostId),
     VoteCounts AS
  (SELECT v.PostId,
          COUNT(v.Id) AS Cnt
   FROM Votes AS v
   JOIN LimitedPosts AS lp ON v.PostId = lp.Id
   GROUP BY v.PostId)
SELECT lp.Title,
       lp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.Cnt, 0) AS CommentCount,
       COALESCE(vc.Cnt, 0) AS VoteCount
FROM LimitedPosts AS lp
JOIN Users AS u ON lp.OwnerUserId = u.Id
LEFT JOIN CommentCounts AS cc ON lp.Id = cc.PostId
LEFT JOIN VoteCounts AS vc ON lp.Id = vc.PostId
ORDER BY lp.CreationDate DESC;