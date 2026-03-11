WITH TopPosts AS
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT U.DisplayName,
       TP.Title,
       TP.CreationDate,
       TP.Score,
       TP.ViewCount
FROM TopPosts TP
JOIN Users U ON TP.OwnerUserId = U.Id;