WITH UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserCommentActivity AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.UserId
),
UserActivity AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.PostCount,
        up.TotalViews,
        up.TotalScore,
        COALESCE(uca.CommentCount, 0) AS CommentCount
    FROM 
        UserPostActivity up
    LEFT JOIN 
        UserCommentActivity uca ON up.UserId = uca.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    CommentCount,
    (PostCount + CommentCount) AS TotalActivity
FROM 
    UserActivity
ORDER BY 
    TotalActivity DESC
LIMIT 10;