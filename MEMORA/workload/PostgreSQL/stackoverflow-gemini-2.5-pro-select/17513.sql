WITH LimitedPosts AS
  (SELECT *
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT u.DisplayName,
       lp.Title,
       lp.CreationDate
FROM Users u
JOIN LimitedPosts lp ON u.Id = lp.OwnerUserId
ORDER BY lp.CreationDate DESC;