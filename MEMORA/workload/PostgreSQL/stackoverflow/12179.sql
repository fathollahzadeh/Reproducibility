SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN P.ViewCount > 0 THEN 1 ELSE 0 END) AS ViewedPosts,
    AVG(U.Reputation) AS AverageUserReputation,
    MAX(P.CreationDate) AS MostRecentPost
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;