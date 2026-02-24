
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPosts,
        STRING_AGG(COALESCE(cr.Name, 'Unknown'), ', ') AS CloseReasons
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
),
RankedUsers AS (
    SELECT 
        ps.UserId,
        ps.DisplayName,
        ps.TotalScore,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalBadges,
        ps.BadgeNames,
        COALESCE(cpr.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(cpr.CloseReasons, 'None') AS CloseReasons,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS ScoreRank
    FROM UserPostStats ps
    LEFT JOIN ClosedPostReasons cpr ON ps.UserId = cpr.UserId
)
SELECT 
    ru.DisplayName,
    ru.TotalScore,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalBadges,
    ru.BadgeNames,
    ru.ClosedPosts,
    ru.CloseReasons,
    CONCAT('User Rank: ', ru.ScoreRank) AS UserRankInfo,
    CASE 
        WHEN ru.ClosedPosts > 0 THEN 'Has closed posts'
        ELSE 'No closed posts'
    END AS PostCloseStatus,
    CASE
        WHEN ru.TotalPosts > 0 THEN ROUND((ru.TotalScore / ru.TotalPosts)::decimal, 2)
        ELSE 0
    END AS AverageScorePerPost
FROM RankedUsers ru
WHERE ru.TotalScore IS NOT NULL
ORDER BY ru.ScoreRank
LIMIT 100;
