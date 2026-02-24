SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score AS PostScore,
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    AVG(P.Score) OVER() AS AveragePostScore,
    COUNT(*) OVER() AS TotalPosts
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    P.CreationDate DESC;