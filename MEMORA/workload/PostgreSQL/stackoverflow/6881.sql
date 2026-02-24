
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(vt.BountyAmount) AS TotalBounty,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes vt ON p.Id = vt.PostId AND vt.VoteTypeId = 8
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS TotalEdits,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalClosures,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS TotalReopens,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.Id END) AS TotalDeletions
    FROM PostHistory ph
    GROUP BY ph.UserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalBounty,
        us.TotalBadges,
        us.TotalViews,
        COALESCE(ps.TotalEdits, 0) AS TotalEdits,
        COALESCE(ps.TotalClosures, 0) AS TotalClosures,
        COALESCE(ps.TotalReopens, 0) AS TotalReopens,
        COALESCE(ps.TotalDeletions, 0) AS TotalDeletions
    FROM UserStats us
    LEFT JOIN PostHistoryStats ps ON us.UserId = ps.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation,
    TotalPosts, 
    TotalQuestions,
    TotalAnswers, 
    TotalBounty,
    TotalBadges,
    TotalViews,
    TotalEdits,
    TotalClosures,
    TotalReopens,
    TotalDeletions
FROM FinalStats
ORDER BY Reputation DESC, TotalPosts DESC
LIMIT 10;
