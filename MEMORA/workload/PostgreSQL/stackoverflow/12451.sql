SELECT 
    P.PostTypeId, 
    COUNT(P.Id) AS TotalPosts, 
    SUM(P.ViewCount) AS TotalViews, 
    COUNT(DISTINCT V.UserId) AS UniqueVoters, 
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.PostTypeId
ORDER BY 
    TotalPosts DESC;