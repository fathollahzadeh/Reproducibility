SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(AVG(vote_counts.VoteCount), 0) AS AvgVotes,
    COALESCE(AVG(comment_counts.CommentCount), 0) AS AvgComments
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) AS vote_counts ON vote_counts.PostId = p.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS comment_counts ON comment_counts.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;