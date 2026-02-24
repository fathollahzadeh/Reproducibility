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
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.Questions, 0) AS TotalQuestions,
        COALESCE(ps.Answers, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalScore,
        ua.TotalViews,
        RANK() OVER (ORDER BY ua.TotalScore DESC, ua.TotalViews DESC) AS ScoreRank
    FROM 
        UserActivity ua
    WHERE 
        ua.BadgeCount > 0 
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    tu.TotalViews,
    tu.ScoreRank,
    (CASE 
         WHEN tu.ScoreRank <= 10 THEN 'Top User'
         WHEN tu.ScoreRank > 10 AND tu.ScoreRank <= 20 THEN 'Promising User'
         ELSE 'Newbie'
     END) AS UserCategory,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.UserId = tu.UserId 
       AND v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR') > 5
ORDER BY 
    tu.ScoreRank
LIMIT 50;