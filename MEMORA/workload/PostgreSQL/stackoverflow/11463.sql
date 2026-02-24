WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Id AS OwnerId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.Id
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS TotalPosts,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostStats ps ON p.Id = ps.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ptc.PostType,
    ptc.TotalPosts,
    ptc.TotalViews,
    ptc.TotalScore
FROM 
    PostStats ps
JOIN 
    PostTypeCounts ptc ON ps.PostId = ptc.TotalPosts
ORDER BY 
    ps.ViewCount DESC;