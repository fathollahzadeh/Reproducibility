
SELECT 
    (SELECT COUNT(*) FROM Posts) AS Total_Posts,
    (SELECT COUNT(*) FROM Users) AS Total_Users,
    (SELECT COUNT(*) FROM Votes) AS Total_Votes,
    (SELECT COUNT(*) FROM Badges) AS Total_Badges,
    (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL) AS Avg_Post_Score,
    (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL) AS Avg_User_Reputation,
    (SELECT AVG(VoteTypeId * 1.0) FROM Votes) AS Avg_Vote_Type,
    (SELECT COUNT(DISTINCT PostId) FROM Comments) AS Total_Commented_Posts,
    (SELECT AVG(LENGTH(Body)) FROM Posts WHERE Body IS NOT NULL) AS Avg_Post_Body_Length
