
SELECT P.Id AS PostId,
       P.Title,
       U.DisplayName AS OwnerDisplayName,
       P.CreationDate,
       P.Score,
       P.ViewCount
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE EXISTS
    (SELECT 1
     FROM
       (SELECT Id
        FROM Posts
        WHERE PostTypeId = 1
        ORDER BY CreationDate DESC
        LIMIT 10) AS LimitedP
     WHERE LimitedP.Id = P.Id)
ORDER BY P.CreationDate DESC;