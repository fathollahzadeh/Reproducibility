WITH RankedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM
        Users u
),
PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS ClosedPostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges b
    GROUP BY
        b.UserId
),
UserPosts AS (
    SELECT
        ps.OwnerUserId,
        COUNT(*) AS TotalPosts
    FROM
        Posts ps
    GROUP BY
        ps.OwnerUserId
)
SELECT
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.ClosedPostCount,
    ps.TotalScore,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    CASE
        WHEN ru.Reputation >= 10000 THEN 'Gold'
        WHEN ru.Reputation >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS ReputationTier
FROM
    RankedUsers ru
LEFT JOIN
    PostStatistics ps ON ru.UserId = ps.OwnerUserId
LEFT JOIN
    UserBadges ub ON ru.UserId = ub.UserId
LEFT JOIN
    UserPosts up ON ru.UserId = up.OwnerUserId
WHERE
    ru.ReputationRank <= 100
ORDER BY
    ru.Reputation DESC;
