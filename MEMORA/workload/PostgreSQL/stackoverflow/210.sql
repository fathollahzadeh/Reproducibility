WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users u
        LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
        LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        TotalViews DESC
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TopUsers
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    ViewRank
FROM 
    RankedUsers
WHERE 
    ViewRank <= 10
    OR (GoldBadges > 0 AND ViewRank <= 20)
ORDER BY 
    ViewRank;
