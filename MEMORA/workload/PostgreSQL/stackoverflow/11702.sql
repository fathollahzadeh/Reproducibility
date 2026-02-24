WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Id, pt.Name
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.CommentCount,
    ps.AvgUserReputation
FROM 
    PostStats ps
ORDER BY 
    ps.PostCount DESC;