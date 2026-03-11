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
       cc.CommentCount,
       vc.UpVotes,
       vc.DownVotes
FROM TopPosts tp
JOIN Users u ON tp.OwnerUserId = u.Id,
                LATERAL
  (SELECT COUNT(c.Id) AS CommentCount
   FROM Comments c
   WHERE c.PostId = tp.Id) cc,
                        LATERAL
  (SELECT COUNT(*) FILTER (
                           WHERE v.VoteTypeId = 2) AS UpVotes,
          COUNT(*) FILTER (
                           WHERE v.VoteTypeId = 3) AS DownVotes
   FROM Votes v
   WHERE v.PostId = tp.Id) vc
ORDER BY tp.CreationDate DESC;