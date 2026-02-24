WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.UserId, ph.PostId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalViews,
    ra.TotalComments,
    ra.LastPostDate,
    COALESCE(phs.HistoryTypes, 'No history') AS LastActivityTypes
FROM UserReputation ur
LEFT JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN RecentActivity ra ON ur.UserId = ra.OwnerUserId
LEFT JOIN PostHistorySummary phs ON ur.UserId = phs.UserId
WHERE ur.Reputation > 1000
ORDER BY ur.Reputation DESC, ps.TotalPosts DESC 
LIMIT 50;