WITH PostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

PostTypesStats AS (
    SELECT
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Name
)

SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.PostCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.CommentCount,
    pts.PostTypeName,
    pts.TotalPosts
FROM 
    PostStats ps
JOIN 
    PostTypesStats pts ON ps.PostCount > 0
ORDER BY 
    ps.PostCount DESC, 
    ps.UpvoteCount DESC;