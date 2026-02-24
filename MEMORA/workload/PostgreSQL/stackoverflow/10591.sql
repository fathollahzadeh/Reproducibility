WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.BadgeCount,
    ps.TotalPosts,
    ps.AvgViewCount,
    ps.AvgScore,
    ps.TotalComments,
    ps.QuestionCount,
    ps.AnswerCount,
    u.TotalViews,
    u.TotalScore,
    u.PostCount
FROM 
    UserStats u
LEFT JOIN 
    PostStats ps ON u.UserId = ps.OwnerUserId
ORDER BY 
    u.Reputation DESC,
    u.BadgeCount DESC,
    u.TotalScore DESC;