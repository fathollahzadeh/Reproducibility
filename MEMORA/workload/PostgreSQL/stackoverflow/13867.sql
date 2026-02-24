
SELECT 
    pt.Name AS PostType,
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS NumberOfPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(COALESCE(votes.VoteCount, 0)) AS AverageVotes,
    AVG(COALESCE(badges.BadgeCount, 0)) AS AverageBadges,
    AVG(COALESCE(cmnt.CommentCount, 0)) AS AverageComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) votes ON p.Id = votes.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) badges ON p.OwnerUserId = badges.UserId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) cmnt ON p.Id = cmnt.PostId
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
