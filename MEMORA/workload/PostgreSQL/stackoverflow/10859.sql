WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(u.UpVotes) AS UpVotes,
        SUM(u.DownVotes) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.PositivePosts,
    ua.NegativePosts,
    ua.TotalComments,
    ua.UpVotes,
    ua.DownVotes,
    bc.BadgeCount,
    ps.PostTypeId,
    ps.TotalPosts,
    ps.AvgScore,
    ps.TotalViews
FROM 
    UserActivity ua
LEFT JOIN 
    BadgeCounts bc ON ua.UserId = bc.UserId
LEFT JOIN 
    PostStatistics ps ON ua.PostCount > 0  
ORDER BY 
    ua.PostCount DESC;