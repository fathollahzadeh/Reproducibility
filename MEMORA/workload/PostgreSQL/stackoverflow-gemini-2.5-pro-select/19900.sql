WITH top_posts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10),
     comment_counts AS
  (SELECT PostId,
          COUNT(Id) AS CommentCount
   FROM Comments
   WHERE PostId IN
       (SELECT Id
        FROM top_posts)
   GROUP BY PostId),
     vote_counts AS
  (SELECT PostId,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 2) AS UpVoteCount,
          COUNT(*) FILTER (
                           WHERE VoteTypeId = 3) AS DownVoteCount
   FROM Votes
   WHERE PostId IN
       (SELECT Id
        FROM top_posts)
   GROUP BY PostId)
SELECT tp.Title,
       tp.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       COALESCE(c.CommentCount, 0) AS CommentCount,
       COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
       COALESCE(v.DownVoteCount, 0) AS DownVoteCount
FROM top_posts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN comment_counts c ON tp.Id = c.PostId
LEFT JOIN vote_counts v ON tp.Id = v.PostId
ORDER BY tp.CreationDate DESC;