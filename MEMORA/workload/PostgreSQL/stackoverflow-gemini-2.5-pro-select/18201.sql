WITH latest_posts AS
  (SELECT p.Id,
          p.Title,
          p.OwnerUserId,
          p.CreationDate,
          p.Score
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.CreationDate DESC
   LIMIT 10)
SELECT lp.Id,
       lp.Title,
       u.DisplayName,
       lp.CreationDate,
       lp.Score
FROM latest_posts lp
JOIN Users u ON lp.OwnerUserId = u.Id
ORDER BY lp.CreationDate DESC;