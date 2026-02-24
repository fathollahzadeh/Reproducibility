WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserStats AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.TotalViews,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    us.DisplayName AS UserWithMostBadges,
    us.BadgeCount,
    us.MaxReputation,
    us.AvgReputation
FROM 
    PostStats ps
CROSS JOIN 
    (SELECT 
        DisplayName, 
        BadgeCount, 
        MaxReputation, 
        AvgReputation
     FROM 
        UserStats 
     ORDER BY 
        BadgeCount DESC 
     LIMIT 1) us
ORDER BY 
    ps.PostCount DESC;