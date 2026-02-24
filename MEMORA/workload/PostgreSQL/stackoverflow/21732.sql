WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgScore,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 10
),
UserBadges AS (
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
UserPerformance AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.QuestionCount,
        tu.AnswerCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        CASE 
            WHEN AVG(tu.AvgScore) IS NULL THEN 'No Score'
            WHEN AVG(tu.AvgScore) > 50 THEN 'High Performer'
            ELSE 'Regular Contributor'
        END AS PerformanceCategory
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
    GROUP BY 
        tu.UserId, tu.DisplayName, tu.QuestionCount, tu.AnswerCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.QuestionCount,
    UP.AnswerCount,
    COALESCE(UP.GoldBadges, 0) AS GoldBadges,
    COALESCE(UP.SilverBadges, 0) AS SilverBadges,
    COALESCE(UP.BronzeBadges, 0) AS BronzeBadges,
    UP.PerformanceCategory,
    (SELECT STRING_AGG(DISTINCT ph.Comment, ', ') 
     FROM PostHistory ph 
     WHERE ph.UserId = UP.UserId AND ph.PostHistoryTypeId IN (10, 11) 
    ) AS UserFeedbackComments,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = UP.UserId)
    ) AS LinkedPostsCount
FROM 
    UserPerformance UP
WHERE 
    UP.QuestionCount > 5 
ORDER BY 
    UP.QuestionCount DESC, UP.AnswerCount DESC;