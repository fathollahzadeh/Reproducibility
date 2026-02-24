SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    AVG(p.ViewCount) AS AvgViewsPerPost,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments,
    SUM(CASE WHEN p.FavoriteCount > 0 THEN 1 ELSE 0 END) AS FavoritePosts,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    SUM(CASE WHEN u.Reputation > 1000 THEN 1 ELSE 0 END) AS HighReputationUsers
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= '2020-01-01' 
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;