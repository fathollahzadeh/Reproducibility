
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)

SELECT 
    up.DisplayName,
    up.PostCount,
    up.TotalScore,
    up.TotalViews,
    ps.PostId,
    ps.Title,
    ps.PostType,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount
FROM 
    UserPosts up
JOIN 
    PostStats ps ON up.UserId = ps.OwnerUserId
ORDER BY 
    up.TotalScore DESC,
    up.PostCount DESC;
