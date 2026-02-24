SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    COUNT(C.Id) AS TotalComments,
    COALESCE(SUM(VoteCount), 0) AS TotalVotes,
    SUM(P.ViewCount) AS TotalViews
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(Id) AS VoteCount 
     FROM 
         Votes 
     GROUP BY 
         PostId) V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalVotes DESC, TotalPosts DESC;