SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL) AS AvgPostScore,
    (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL) AS AvgUserReputation,
    (SELECT COUNT(DISTINCT PostId) FROM Votes WHERE VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(DISTINCT PostId) FROM Votes WHERE VoteTypeId = 3) AS TotalDownVotes,
    (SELECT COUNT(DISTINCT PostId) FROM PostHistory WHERE PostHistoryTypeId IN (10, 11)) AS TotalPostClosures,
    (SELECT COUNT(DISTINCT PostId) FROM PostLinks) AS TotalPostLinks,
    (SELECT COUNT(*) FROM Tags) AS TotalTags;