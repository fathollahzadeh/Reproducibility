SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    U.CreationDate AS UserCreationDate,
    COUNT(V.Id) AS VoteCount,
    COUNT(B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.Id, U.DisplayName, U.Reputation, U.CreationDate
ORDER BY 
    P.CreationDate DESC;