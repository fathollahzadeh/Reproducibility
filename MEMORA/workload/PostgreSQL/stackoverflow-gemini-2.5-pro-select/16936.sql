WITH LimitedPosts AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.OwnerUserId
   FROM Posts AS p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT lp.Title,
       lp.CreationDate,
       u.DisplayName AS OwnerDisplayName,

  (SELECT COUNT(c.Id)
   FROM Comments AS c
   WHERE c.PostId = lp.Id) AS CommentCount,

  (SELECT COUNT(v.Id)
   FROM Votes AS v
   WHERE v.PostId = lp.Id) AS VoteCount
FROM LimitedPosts AS lp
JOIN Users AS u ON lp.OwnerUserId = u.Id
ORDER BY lp.CreationDate DESC;