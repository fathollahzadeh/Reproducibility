
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT AVG(Score) FROM Posts) AS AvgPostScore,
    (SELECT AVG(Reputation) FROM Users) AS AvgUserReputation,
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts WHERE OwnerUserId IS NOT NULL) AS UniquePostOwners,
    (SELECT COUNT(DISTINCT UserId) FROM Comments WHERE UserId IS NOT NULL) AS UniqueCommentUsers
