WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
AvgPostScores AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.PositivePosts,
        ups.NegativePosts,
        ups.TotalViews,
        ups.CommentCount,
        ups.BadgeCount,
        COALESCE(aps.AverageScore, 0) AS AverageScore
    FROM 
        UserPostStats ups
    LEFT JOIN 
        AvgPostScores aps ON ups.UserId = aps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    PositivePosts,
    NegativePosts,
    TotalViews,
    CommentCount,
    BadgeCount,
    AverageScore
FROM 
    UserEngagement
WHERE 
    PostCount > 0
ORDER BY 
    TotalViews DESC, AverageScore DESC
LIMIT 10;
