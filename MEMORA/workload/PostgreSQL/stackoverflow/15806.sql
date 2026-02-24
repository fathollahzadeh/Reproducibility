
SELECT 
    Users.DisplayName, 
    COUNT(Posts.Id) AS NumberOfPosts, 
    SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount, 
    SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount 
FROM 
    Users 
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId 
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId 
GROUP BY 
    Users.DisplayName 
ORDER BY 
    NumberOfPosts DESC;
