WITH UserBadgeCounts AS (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges
    GROUP BY
        UserId
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY
        p.OwnerUserId
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.AvgPostScore, 0) AS AvgPostScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.TotalViews, 0) DESC) AS EngagementRank
    FROM
        Users u
    LEFT JOIN
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT
    UserId,
    DisplayName,
    BadgeCount,
    PostCount,
    AvgPostScore,
    TotalViews,
    TotalAnswers,
    EngagementRank
FROM
    UserEngagement
WHERE
    EngagementRank <= 10
ORDER BY
    EngagementRank;