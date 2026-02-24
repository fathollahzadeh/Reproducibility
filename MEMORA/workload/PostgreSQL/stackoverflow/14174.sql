
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.AnswerCount) AS AvgAnswerCount,
    AVG(p.CommentCount) AS AvgCommentCount,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) AS AvgPostAgeInSeconds,
    COUNT(DISTINCT p.OwnerUserId) AS DistinctUsersContributed,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
