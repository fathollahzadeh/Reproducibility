SELECT 
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT AVG(ViewCount) FROM Posts) AS AveragePostViews,
    (SELECT AVG(Score) FROM Posts) AS AveragePostScore,
    (SELECT AVG(Reputation) FROM Users) AS AverageUserReputation