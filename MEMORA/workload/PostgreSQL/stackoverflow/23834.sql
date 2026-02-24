
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
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS PostsMade,
        COALESCE(ps.TotalScore, 0) AS Score,
        COALESCE(ps.TotalAnswers, 0) AS AnswersGiven,
        CASE 
            WHEN COALESCE(ps.QuestionCount, 0) > 0 
            THEN ROUND(COALESCE(ps.TotalScore, 0) / COALESCE(ps.QuestionCount, 1), 2)
            ELSE 0
        END AS AvgScorePerQuestion,
        ub.BadgeCount AS TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 100
),
TopUsers AS (
    SELECT 
        ue.*,
        RANK() OVER (ORDER BY ue.Score DESC, ue.PostsMade DESC) AS ScoreRank
    FROM 
        UserEngagement ue
)
SELECT 
    tu.DisplayName,
    tu.PostsMade,
    tu.Score,
    tu.AvgScorePerQuestion,
    tu.TotalBadges,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    CASE 
        WHEN tu.ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorCategory,
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = tu.UserId 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
        AND p.Title NOT LIKE '%deleted%'
        ) AS ActiveInPastYear
FROM 
    TopUsers tu
WHERE 
    tu.ScoreRank <= 50
ORDER BY 
    tu.Score DESC, tu.PostsMade DESC;
