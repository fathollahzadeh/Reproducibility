
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COUNT(B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
