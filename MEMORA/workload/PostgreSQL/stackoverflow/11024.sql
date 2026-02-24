WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        AVG(c.CommentCount) AS AvgComments
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentCount
         FROM Comments
         GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(ps.AvgComments, 0) AS AvgComments
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.AvgScore,
    us.AvgComments
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC;