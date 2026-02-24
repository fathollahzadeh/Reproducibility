WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
RankedUsers AS (
    SELECT 
        ua.*,
        RANK() OVER (ORDER BY ua.TotalScore DESC, ua.TotalViews DESC) AS ScoreRank
    FROM UserAggregates ua
)
SELECT 
    ru.DisplayName,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.Questions,
    ru.Answers,
    ru.TotalScore,
    ru.TotalViews,
    CASE 
        WHEN ru.ScoreRank <= 10 THEN 'Top User'
        WHEN ru.ScoreRank <= 50 THEN 'Moderate User'
        ELSE 'New User'
    END AS UserCategory
FROM RankedUsers ru
WHERE ru.TotalScore > 0
ORDER BY ru.ScoreRank
FETCH FIRST 20 ROWS ONLY;
