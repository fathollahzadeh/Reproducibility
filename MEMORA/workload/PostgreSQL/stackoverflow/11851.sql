
WITH PostStats AS (
    SELECT
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(c.Score), 0) AS TotalComments,
        COALESCE(AVG(p.Score), 0) AS AvgScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes  
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.PostTypeId
)

SELECT 
    pt.Name AS PostTypeName,
    ps.TotalPosts,
    ps.TotalComments,
    ps.AvgScore,
    ps.TotalUpVotes,
    ps.TotalDownVotes
FROM 
    PostTypes pt
LEFT JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;
