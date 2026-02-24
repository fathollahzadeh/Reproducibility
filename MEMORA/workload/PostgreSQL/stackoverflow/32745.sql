WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        MAX(p.CreationDate) AS MostRecentPost
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(up.TotalBounties, 0) AS TotalBounties,
        (COALESCE(up.Upvotes, 0) - COALESCE(up.Downvotes, 0)) AS ReputationScore,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.MostRecentPost
    FROM Users u
    LEFT JOIN UserReputation up ON u.Id = up.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount,
        MIN(ph.CreationDate) AS FirstClosedPostDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.UserId
),
UserActivity AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.ReputationScore,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.MostRecentPost,
        COALESCE(cph.ClosedPostCount, 0) AS ClosedPosts
    FROM UserStats us
    LEFT JOIN ClosedPostHistory cph ON us.UserId = cph.UserId
)
SELECT 
    ua.DisplayName,
    ua.ReputationScore,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.ClosedPosts,
    CASE 
        WHEN ua.ClosedPosts > 5 THEN 'Active Contributor'
        WHEN ua.ReputationScore >= 100 THEN 'Reputable User'
        ELSE 'New User'
    END AS UserCategory,
    RANK() OVER (ORDER BY ua.ReputationScore DESC) AS UserRank
FROM UserActivity ua
WHERE ua.TotalPosts > 10
ORDER BY ua.ReputationScore DESC, ua.TotalPosts DESC;