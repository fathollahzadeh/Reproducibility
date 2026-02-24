SELECT 
    (SELECT COUNT(*) FROM Posts) AS Total_Posts,
    (SELECT COUNT(*) FROM Users) AS Total_Users,
    (SELECT COUNT(*) FROM Votes) AS Total_Votes,
    AVG(Reputation) AS Average_User_Reputation 
FROM 
    Users;