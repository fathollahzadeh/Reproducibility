SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON U.Id = C.UserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.CreationDate >= '2020-01-01'  
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
ORDER BY 
    U.Reputation DESC;