WITH UserStatistics AS (
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
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedCount
    FROM 
        Posts p
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
CombinedStatistics AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(pm.PostCount, 0) AS TotalPosts,
        COALESCE(pm.QuestionCount, 0) AS TotalQuestions,
        COALESCE(pm.AnswerCount, 0) AS TotalAnswers,
        COALESCE(pm.AvgViewCount, 0) AS AverageViewCount,
        COALESCE(pm.TotalScore, 0) AS TotalScore,
        COALESCE(cp.ClosedCount, 0) AS TotalClosedPosts,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges
    FROM 
        UserStatistics u
    LEFT JOIN 
        PostMetrics pm ON u.UserId = pm.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON u.UserId = cp.OwnerUserId
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts = 0 THEN 'No Posts'
        ELSE CONCAT('Active: ', TotalPosts, ' | Questions: ', TotalQuestions, ' | Answers: ', TotalAnswers)
    END AS ActivitySummary,
    CASE 
        WHEN Reputation < 100 THEN 'Newbie'
        WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel,
    CASE 
        WHEN BadgeCount IS NULL THEN 'No Badges'
        ELSE CONCAT('Badges - Gold: ', GoldBadges, ', Silver: ', SilverBadges, ', Bronze: ', BronzeBadges)
    END AS BadgeSummary
FROM 
    CombinedStatistics
WHERE 
    Reputation > 50
ORDER BY 
    Reputation DESC, TotalScore DESC;