WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
AggregatedStats AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        ubs.Reputation,
        ubs.BadgeCount,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalViews,
        ps.TotalScore
    FROM 
        UserBadgeStats ubs
    LEFT JOIN 
        PostStats ps ON ubs.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(QuestionCount, 0) AS QuestionCount,
    COALESCE(AnswerCount, 0) AS AnswerCount,
    COALESCE(TotalViews, 0) AS TotalViews,
    COALESCE(TotalScore, 0) AS TotalScore
FROM 
    AggregatedStats
ORDER BY 
    Reputation DESC, BadgeCount DESC
LIMIT 100;
