SELECT
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.ViewCount,
    P.Score
FROM
    Posts P
JOIN
    Users U ON P.OwnerUserId = U.Id
WHERE
    P.PostTypeId = 1  
ORDER BY
    P.CreationDate DESC
LIMIT 10;