WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AvgAnswers,
        AVG(p.CommentCount) AS AvgComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgAnswers, 0) AS AvgAnswers,
        COALESCE(ps.AvgComments, 0) AS AvgComments
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 100
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.BadgeCount,
    au.PostCount,
    au.TotalScore,
    au.TotalViews,
    au.AvgAnswers,
    au.AvgComments
FROM 
    ActiveUsers au
ORDER BY 
    au.TotalScore DESC,
    au.BadgeCount DESC
LIMIT 10;
