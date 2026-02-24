
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ur.ReputationRank,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore,
        ps.LastPostDate
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE ur.ReputationRank <= 100 
),
ClosedPostsStats AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostsCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
)
SELECT 
    au.DisplayName,
    au.ReputationRank,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(cps.ClosedPostsCount, 0) AS ClosedPostsCount,
    COALESCE(cps.CloseReasons, 'None') AS CloseReasons,
    CASE 
        WHEN COALESCE(ps.TotalPosts, 0) > 0 THEN ROUND(COALESCE(ps.TotalScore, 0) * 1.0 / COALESCE(ps.TotalPosts, 1), 2)
        ELSE NULL 
    END AS AverageScorePerPost,
    RANK() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC) AS ScoreRank
FROM ActiveUsers au
LEFT JOIN PostStats ps ON au.Id = ps.OwnerUserId
LEFT JOIN ClosedPostsStats cps ON au.Id = cps.UserId
ORDER BY ScoreRank, au.DisplayName;
