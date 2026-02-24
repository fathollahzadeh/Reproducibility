SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    COUNT(C.ID) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, U.Reputation, P.Title, P.CreationDate, P.Score
ORDER BY 
    P.CreationDate DESC
LIMIT 100;