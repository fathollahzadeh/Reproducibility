WITH PostUsers AS
  (SELECT p.Id,
          p.Title,
          p.CreationDate,
          p.Score,
          u.DisplayName
   FROM Posts p
   JOIN Users u ON p.OwnerUserId = u.Id
   WHERE p.PostTypeId = 1)
SELECT pu.DisplayName,
       pu.Title,
       pu.CreationDate,
       pu.Score,
       COUNT(c.Id) AS CommentCount
FROM PostUsers pu
LEFT JOIN Comments c ON pu.Id = c.PostId
GROUP BY pu.DisplayName,
         pu.Title,
         pu.CreationDate,
         pu.Score
ORDER BY pu.CreationDate DESC
LIMIT 10;