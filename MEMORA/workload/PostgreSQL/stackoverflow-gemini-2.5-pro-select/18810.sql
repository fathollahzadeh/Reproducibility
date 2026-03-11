WITH LimitedPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     CommentCounts AS
  (SELECT PostId,
          COUNT(Id) AS CommentCount
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM LimitedPosts)
   GROUP BY PostId),
     VoteCounts AS
  (SELECT PostId,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 2) AS UpVotes,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 3) AS DownVotes
   FROM Votes
   WHERE PostId IN
       (SELECT Id
        FROM LimitedPosts)
   GROUP BY PostId)
SELECT p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(cc.CommentCount, 0) AS CommentCount,
       COALESCE(vc.UpVotes, 0) AS UpVotes,
       COALESCE(vc.DownVotes, 0) AS DownVotes
FROM LimitedPosts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN CommentCounts cc ON p.Id = cc.PostId
LEFT JOIN VoteCounts vc ON p.Id = vc.PostId
ORDER BY p.CreationDate DESC;