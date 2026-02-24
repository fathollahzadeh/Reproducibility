WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.AvgScore,
        us.TotalViews,
        us.TotalComments,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        Users u
    JOIN 
        PostStats us ON u.Id = us.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    au.DisplayName,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount,
    au.AvgScore,
    au.TotalViews,
    au.TotalComments,
    COALESCE(au.BadgeCount, 0) AS BadgeCount,
    COALESCE(au.HighestBadgeClass, 0) AS HighestBadgeClass
FROM 
    ActiveUsers au
ORDER BY 
    au.AvgScore DESC, 
    au.TotalViews DESC
LIMIT 10;
