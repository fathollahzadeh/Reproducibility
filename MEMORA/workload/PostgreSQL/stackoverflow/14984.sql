
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    COALESCE(ROUND(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.Id), 0), 2), 0) AS AvgUpvoteScorePerPost,
    COALESCE(ROUND(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT p.Id), 0), 2), 0) AS AvgDownvoteScorePerPost 
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
