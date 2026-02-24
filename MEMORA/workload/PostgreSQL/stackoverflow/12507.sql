SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.UpVotes,
    U.DownVotes,
    COUNT(P.Id) AS TotalPosts,
    COUNT(C.Id) AS TotalComments,
    AVG(P.Score) AS AveragePostScore,
    MAX(P.LastActivityDate) AS MostRecentPostActivity
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC;