
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.UserName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.UpVotes,
    u.DownVotes,
    COALESCE(ROUND((CAST(u.UpVotes AS FLOAT) / NULLIF(u.TotalPosts, 0)) * 100, 2), 0) AS UpvotePercentage  
FROM 
    UserPostStats u
ORDER BY 
    u.TotalPosts DESC;
