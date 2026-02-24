WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
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
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalViews,
    us.TotalScore,
    us.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserStatistics us
LEFT JOIN 
    PostStatistics ps ON us.UserId = ps.PostId
ORDER BY 
    us.TotalViews DESC, us.TotalScore DESC;