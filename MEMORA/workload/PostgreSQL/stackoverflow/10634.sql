
SELECT 
    p.Title AS Post_Title,
    p.CreationDate AS Post_CreationDate,
    u.DisplayName AS Owner_DisplayName,
    p.ViewCount AS Post_ViewCount,
    p.AnswerCount AS Total_Answers,
    p.CommentCount AS Total_Comments,
    pt.Name AS Post_Type,
    COUNT(v.Id) AS Total_Votes,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) AS Average_UpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END) AS Average_DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.AnswerCount, p.CommentCount, pt.Name
ORDER BY 
    p.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
