
SELECT 
    p.Title AS Post_Title,
    p.CreationDate AS Post_Creation_Date,
    p.ViewCount AS Post_View_Count,
    p.Score AS Post_Score,
    u.DisplayName AS Owner_Display_Name,
    COUNT(c.Id) AS Comment_Count,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvote_Count,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvote_Count
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
