SELECT 
    P.PostTypeId,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    AVG(U.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT U.Id) AS TotalUsers,
    AVG(P.Score) AS AveragePostScore,
    SUM(P.ViewCount) AS TotalViewCount,
    SUM(P.CommentCount) AS TotalCommentCount,
    COUNT(DISTINCT P.OwnerUserId) AS UniquePostOwners
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
GROUP BY 
    P.PostTypeId
ORDER BY 
    P.PostTypeId;