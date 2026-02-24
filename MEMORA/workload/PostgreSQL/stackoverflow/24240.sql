WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
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
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC) AS Rank
    FROM 
        UserBadgeStats
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
FinalReport AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        UPPER(u.Location) AS Location,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
        COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ps.PositiveScoreCount, 0) AS TotalPositiveScores,
        tb.BadgeCount,
        tb.GoldBadges,
        tb.SilverBadges,
        tb.BronzeBadges,
        tb.Rank
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        TopUsers tb ON u.Id = tb.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.Location,
    fr.TotalPosts,
    fr.TotalQuestions,
    fr.TotalAnswers,
    fr.TotalPositiveScores,
    fr.BadgeCount,
    fr.GoldBadges,
    fr.SilverBadges,
    fr.BronzeBadges,
    fr.Rank
FROM 
    FinalReport fr
WHERE 
    (fr.Reputation IS NOT NULL OR fr.BadgeCount > 0) 
    AND (fr.TotalPosts > 0 OR fr.TotalQuestions > 0 OR fr.TotalAnswers > 0)
ORDER BY 
    fr.Rank ASC,
    fr.Reputation DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;