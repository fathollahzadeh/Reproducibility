WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
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
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalViews
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews
FROM 
    CombinedStats
WHERE 
    (PostCount > 10 OR GoldBadges > 0)
ORDER BY 
    TotalViews DESC, PostCount DESC
LIMIT 100;
