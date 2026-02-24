WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(CASE WHEN p.ViewCount > 0 THEN p.ViewCount ELSE NULL END) AS AvgViewCount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 END) AS TotalReopenUndeleteVotes,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.AvgViewCount,
        COALESCE(pht.TotalCloseVotes, 0) AS TotalCloseVotes,
        COALESCE(pht.TotalReopenUndeleteVotes, 0) AS TotalReopenUndeleteVotes,
        pht.LastActionDate
    FROM 
        UserPostStats ups
        LEFT JOIN PostHistoryStats pht ON ups.UserId = pht.UserId
)
SELECT 
    cs.DisplayName,
    cs.TotalPosts,
    cs.TotalQuestions,
    cs.TotalAnswers,
    cs.AvgViewCount,
    cs.TotalCloseVotes,
    cs.TotalReopenUndeleteVotes,
    cs.LastActionDate,
    CASE 
        WHEN cs.TotalQuestions > 100 THEN 'Expert'
        WHEN cs.TotalQuestions BETWEEN 50 AND 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    CASE 
        WHEN cs.AvgViewCount IS NULL THEN 'No Views'
        WHEN cs.AvgViewCount > 1000 THEN 'High Engagement'
        WHEN cs.AvgViewCount BETWEEN 100 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    (SELECT STRING_AGG(b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = cs.UserId 
     AND b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
     GROUP BY b.UserId) AS RecentBadges
FROM 
    CombinedStats cs
WHERE 
    cs.TotalPosts > 0
ORDER BY 
    cs.TotalPosts DESC,
    cs.DisplayName ASC
LIMIT 50;