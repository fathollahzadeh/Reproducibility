SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(VoteCount) FROM 
        (SELECT COUNT(*) AS VoteCount 
         FROM Votes 
         GROUP BY PostId) AS PostVoteCounts) AS AverageVotesPerPost