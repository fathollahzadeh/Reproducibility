
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), PostStats AS (
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
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.PostCount, 0) AS PostCount,
        COALESCE(pb.QuestionCount, 0) AS QuestionCount,
        COALESCE(pb.AnswerCount, 0) AS AnswerCount,
        COALESCE(pb.TotalViews, 0) AS TotalViews,
        COALESCE(pb.TotalScore, 0) AS TotalScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY COALESCE(pb.TotalScore, 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        PostStats pb ON u.Id = pb.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Rank
FROM 
    UserActivity
WHERE 
    PostCount > 0
ORDER BY 
    Rank;
