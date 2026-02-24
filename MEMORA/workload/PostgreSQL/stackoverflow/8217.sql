WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ClosedPostCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(cpc.ClosedPostCount, 0) AS ClosedPostCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ClosedPostCounts cpc ON u.Id = cpc.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews,
    ClosedPostCount,
    RANK() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS PerformanceRank
FROM UserPerformance
WHERE Reputation > 100
ORDER BY PerformanceRank, TotalScore DESC;
