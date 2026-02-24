
SELECT 
    (SELECT COUNT(*) FROM Posts) AS Total_Posts,
    (SELECT COUNT(*) FROM Users) AS Total_Users,
    (SELECT COUNT(*) FROM Comments) AS Total_Comments,
    (SELECT COUNT(*) FROM Votes) AS Total_Votes,
    (SELECT COUNT(*) FROM Badges) AS Total_Badges,
    (SELECT COUNT(*) FROM Tags) AS Total_Tags,
    (SELECT COUNT(*) FROM PostHistory) AS Total_PostHistories,
    (SELECT COUNT(*) FROM PostLinks) AS Total_PostLinks
