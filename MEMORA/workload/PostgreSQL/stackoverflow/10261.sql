SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
    SUM(P.ViewCount) AS TotalViews,
    AVG(P.Score) AS AverageScore,
    AVG(COALESCE(P.AnswerCount, 0)) AS AverageAnswerCount,
    AVG(COALESCE(P.CommentCount, 0)) AS AverageCommentCount,
    COUNT(DISTINCT P.OwnerUserId) AS UniquePostOwners,
    AVG(UP.Reputation) AS AverageUserReputation
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
JOIN 
    Users UP ON P.OwnerUserId = UP.Id
GROUP BY 
    PT.Name
ORDER BY 
    TotalPosts DESC;