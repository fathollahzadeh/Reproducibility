SELECT 
    Users.DisplayName,
    COUNT(Posts.Id) AS PostCount,
    SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
FROM 
    Users
LEFT JOIN 
    Posts ON Users.Id = Posts.OwnerUserId
LEFT JOIN 
    Votes ON Posts.Id = Votes.PostId
GROUP BY 
    Users.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
