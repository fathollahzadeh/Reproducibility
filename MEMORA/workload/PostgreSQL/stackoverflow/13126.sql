SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalQuestionsWithPositiveScore,
    AVG(u.Reputation) AS AverageUserReputation,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalPostsClosed,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalPostsReopened,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;