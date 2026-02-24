
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserDetails AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.PositiveScoreCount,
        ups.NegativeScoreCount,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserPostStatistics ups
    LEFT JOIN 
        FilteredBadges b ON ups.UserId = b.UserId
)
SELECT 
    ud.DisplayName,
    ud.TotalPosts,
    ud.QuestionCount,
    ud.AnswerCount,
    ud.PositiveScoreCount,
    ud.NegativeScoreCount,
    ud.GoldBadges,
    ud.SilverBadges,
    ud.BronzeBadges,
    CASE 
        WHEN (ud.GoldBadges + ud.SilverBadges + ud.BronzeBadges) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN ud.TotalPosts IS NULL OR ud.TotalPosts = 0 THEN 'No Activity'
        WHEN ud.AnswerCount > 0 AND ud.QuestionCount > 0 THEN 'Active Contributor'
        ELSE 'Lurker'
    END AS UserActivityStatus
FROM 
    UserDetails ud
WHERE 
    ud.TotalPosts > 10
ORDER BY 
    ud.TotalPosts DESC, ud.DisplayName ASC;
