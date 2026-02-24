SELECT 
    DATE_TRUNC('day', p.CreationDate) AS post_date,
    COUNT(DISTINCT p.Id) AS total_posts,
    COUNT(DISTINCT c.Id) AS total_comments,
    COUNT(DISTINCT u.Id) AS active_users,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS total_questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS total_answers,
    SUM(CASE WHEN p.PostTypeId = 10 THEN 1 ELSE 0 END) AS total_closed_posts,
    SUM(CASE WHEN p.PostTypeId = 11 THEN 1 ELSE 0 END) AS total_reopened_posts
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id OR c.UserId = u.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
GROUP BY 
    post_date
ORDER BY 
    post_date ASC;