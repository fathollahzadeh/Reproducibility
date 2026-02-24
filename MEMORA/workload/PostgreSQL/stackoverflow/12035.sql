SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COALESCE(SUM(v.vote_count), 0) AS TotalVotes,
    COALESCE(SUM(c.comment_count), 0) AS TotalComments,
    COALESCE(SUM(b.badge_count), 0) AS TotalBadges,
    COUNT(DISTINCT t.Id) AS TotalTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2  
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS vote_count FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS comment_count FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS badge_count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
LEFT JOIN 
    (SELECT DISTINCT unnest(string_to_array(Tags, ',')) AS Tag, Id FROM Posts) t ON t.Id = p.Id
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalVotes DESC;