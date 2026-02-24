SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    COUNT(V.Id) AS TotalVotes,
    COUNT(B.Id) AS TotalBadges,
    AVG(P.Score) AS AveragePostScore,
    AVG(V.BountyAmount) AS AverageBountyAmount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC;