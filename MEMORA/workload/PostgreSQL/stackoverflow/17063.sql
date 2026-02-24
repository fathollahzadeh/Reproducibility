
SELECT 
    Users.DisplayName,
    COUNT(Posts.Id) AS PostCount,
    SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
GROUP BY 
    Users.Id, Users.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
