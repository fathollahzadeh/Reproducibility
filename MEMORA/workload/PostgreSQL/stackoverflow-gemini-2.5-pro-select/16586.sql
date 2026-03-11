WITH TopPosts AS
  (SELECT Id
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
        FROM TopPosts)
   GROUP BY PostId),
     VoteCounts AS
  (SELECT PostId,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 2) AS UpVotes,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 3) AS DownVotes
   FROM Votes
   WHERE VoteTypeId IN (2,
                        3)
     AND PostId IN
       (SELECT Id
        FROM TopPosts)
   GROUP BY PostId)
SELECT p.Title,
       p.CreationDate,
       u.DisplayName AS Author,
       COALESCE(cc.Cnt, 0) AS CommentCount,
       COALESCE(vc.UpVotes, 0) AS UpVotes,
       COALESCE(vc.DownVotes, 0) AS DownVotes
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN TopPosts tp ON p.Id = tp.Id
LEFT JOIN CommentCounts cc ON p.Id = cc.PostId
LEFT JOIN VoteCounts vc ON p.Id = vc.PostId
ORDER BY p.CreationDate DESC;