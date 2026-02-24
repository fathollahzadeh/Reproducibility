SELECT 
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
    SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
