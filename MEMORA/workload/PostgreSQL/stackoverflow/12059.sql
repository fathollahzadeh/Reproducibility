
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,  
        COALESCE(COUNT(c.Id), 0) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2024-01-01'  
    GROUP BY 
        p.PostTypeId
)
SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.TotalComments
FROM 
    PostTypes pt
JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;
