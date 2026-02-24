WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionsStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.CreationDate) AS LastQuestionDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        qs.QuestionCount,
        qs.TotalScore,
        qs.AverageViews,
        qs.LastQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        QuestionsStatistics qs ON u.Id = qs.OwnerUserId
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        QuestionCount,
        TotalScore,
        AverageViews,
        LastQuestionDate,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalScore DESC) AS Rank
    FROM 
        UserActivity
)

SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    QuestionCount,
    TotalScore,
    AverageViews,
    LastQuestionDate,
    Rank
FROM 
    RankedUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
