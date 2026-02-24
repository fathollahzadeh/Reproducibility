WITH UserBadges AS (
    SELECT
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges
    GROUP BY
        UserId
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews
    FROM
        Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
        AND (ps.QuestionCount + ps.AnswerCount) > 0
),
RankedUsers AS (
    SELECT
        au.*,
        ROW_NUMBER() OVER (ORDER BY au.TotalScore DESC, au.TotalViews DESC) AS UserRank
    FROM
        ActiveUsers au
)
SELECT 
    ru.DisplayName,
    ru.TotalBadges,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.TotalScore,
    ru.TotalViews,
    CASE 
        WHEN ru.TotalBadges >= 10 THEN 'Expert'
        WHEN ru.TotalBadges >= 5 THEN 'Intermediate'
        ELSE 'Novice' 
    END AS UserLevel
FROM
    RankedUsers ru
WHERE
    ru.UserRank <= 10
ORDER BY
    ru.UserRank;