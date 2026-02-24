
SELECT 
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT AVG(CAST(Reputation AS FLOAT)) FROM Users) AS AverageReputation,
    (SELECT AVG(CAST(Score AS FLOAT)) FROM Posts) AS AveragePostScore
FROM 
    (SELECT 1) AS dummy;
