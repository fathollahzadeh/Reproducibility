SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    AVG(ViewCount) AS AveragePostViews,
    AVG((SELECT COUNT(*) FROM Votes WHERE Votes.PostId = Posts.Id)) AS AverageVotesPerPost
FROM Posts;