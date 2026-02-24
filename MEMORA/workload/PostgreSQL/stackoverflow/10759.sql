SELECT 
    U.Id AS UserId,
    U.Reputation,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS PostCount,
    COUNT(DISTINCT V.Id) AS TotalVotes,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.Reputation, U.DisplayName
ORDER BY 
    U.Reputation DESC;