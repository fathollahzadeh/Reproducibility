WITH TopPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT tp.Title,
       tp.CreationDate,
       u.DisplayName AS OwnerDisplayName,

  (SELECT COUNT(Id)
   FROM Comments c
   WHERE c.PostId = tp.Id) AS CommentCount,

  (SELECT COUNT(*) FILTER (
                           WHERE VoteTypeId = 2)
   FROM Votes v
   WHERE v.PostId = tp.Id) AS UpVoteCount,

  (SELECT COUNT(*) FILTER (
                           WHERE VoteTypeId = 3)
   FROM Votes v
   WHERE v.PostId = tp.Id) AS DownVoteCount
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY tp.CreationDate DESC;