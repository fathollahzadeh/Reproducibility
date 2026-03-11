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
       TopPosts.Title,
       TopPosts.CreationDate,
       TopPosts.Score,
       TopPosts.ViewCount
FROM Users U
JOIN TopPosts ON U.Id = TopPosts.OwnerUserId;