WITH TopPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT tp.Id AS PostId,
       tp.Title,
       tp.CreationDate,
       u.DisplayName AS Author,
       COALESCE(c.CommentCount, 0) AS CommentCount,
       COALESCE(v.UpVotes, 0) AS UpVotes,
       COALESCE(v.DownVotes, 0) AS DownVotes
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN
  (SELECT c.PostId,
          COUNT(c.Id) AS CommentCount
   FROM Comments c
   JOIN TopPosts t ON c.PostId = t.Id
   GROUP BY c.PostId) c ON tp.Id = c.PostId
LEFT JOIN
  (SELECT v.PostId,
          COUNT(*) FILTER (
                           WHERE v.VoteTypeId = 2) AS UpVotes,
          COUNT(*) FILTER (
                           WHERE v.VoteTypeId = 3) AS DownVotes
   FROM Votes v
   JOIN TopPosts t ON v.PostId = t.Id
   GROUP BY v.PostId) v ON tp.Id = v.PostId
ORDER BY tp.CreationDate DESC;