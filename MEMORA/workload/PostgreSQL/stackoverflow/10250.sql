WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalViews,
    us.TotalScore,
    us.BadgeCount,
    pts.PostType,
    pts.TotalPosts,
    pts.AvgScore,
    pts.TotalViews AS PostTypeTotalViews,
    cs.CommentCount,
    cs.TotalCommentScore
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostTypeStats pts ON pts.PostType = (
        SELECT pt.Name 
        FROM PostTypes pt 
        WHERE pt.Id = p.PostTypeId
    )
LEFT JOIN 
    CommentStats cs ON p.Id = cs.PostId
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC;