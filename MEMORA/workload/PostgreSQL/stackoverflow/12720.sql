WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ps.PostCount,
        ps.TotalScore,
        ps.TotalViews,
        ps.QuestionCount,
        ps.AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(TotalScore, 0) AS TotalScore,
    COALESCE(TotalViews, 0) AS TotalViews,
    COALESCE(QuestionCount, 0) AS QuestionCount,
    COALESCE(AnswerCount, 0) AS AnswerCount
FROM 
    UserPerformance
ORDER BY 
    Reputation DESC, 
    TotalScore DESC;