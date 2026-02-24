
SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(post_votes.votes_per_post) AS AvgVotesPerPost,
    AVG(post_comments.comments_per_post) AS AvgCommentsPerPost
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS votes_per_post 
     FROM 
        Votes 
     GROUP BY 
        PostId) AS post_votes ON p.Id = post_votes.PostId
JOIN 
    (SELECT 
        PostId, 
        COUNT(*) AS comments_per_post 
     FROM 
        Comments 
     GROUP BY 
        PostId) AS post_comments ON p.Id = post_comments.PostId
GROUP BY 
    p.Id, post_votes.votes_per_post, post_comments.comments_per_post;
