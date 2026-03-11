WITH FilteredPosts AS
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10),
     Aggregates AS
  (SELECT p.Id,
          COUNT(DISTINCT c.Id) AS CommentCount,
          COUNT(DISTINCT CASE
                             WHEN v.VoteTypeId = 2 THEN v.Id
                         END) AS UpVotes,
          COUNT(DISTINCT CASE
                             WHEN v.VoteTypeId = 3 THEN v.Id
                         END) AS DownVotes
   FROM FilteredPosts p
   LEFT JOIN Comments c ON p.Id = c.PostId
   LEFT JOIN Votes v ON p.Id = v.PostId
   GROUP BY p.Id)
SELECT fp.Title,
       fp.CreationDate,
       u.DisplayName AS Author,
       a.CommentCount,
       a.UpVotes,
       a.DownVotes
FROM FilteredPosts fp
JOIN Users u ON fp.OwnerUserId = u.Id
JOIN Aggregates a ON fp.Id = a.Id
ORDER BY fp.CreationDate DESC;