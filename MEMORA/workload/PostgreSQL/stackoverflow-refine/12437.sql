
SELECT
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) AS AvgQuestionScore,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT MAX(Reputation) FROM Users) AS HighestReputation
