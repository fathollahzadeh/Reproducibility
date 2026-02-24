WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users u
),

PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.Score) AS HighestScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),

Leaderboard AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AverageViews,
        ps.HighestScore,
        ROW_NUMBER() OVER (PARTITION BY ur.ReputationCategory ORDER BY ur.Reputation DESC) AS Rank
    FROM UserReputation ur
    LEFT JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
    WHERE ur.Reputation >= 0
),

RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        pt.Name AS PostTypeName,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 'Closed/Reopened/Deleted'
            WHEN ph.PostHistoryTypeId = 66 THEN 'Created From Wizard'
            ELSE 'General'
        END AS ActionType
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)

SELECT 
    lb.DisplayName,
    lb.Reputation,
    lb.TotalPosts,
    lb.TotalQuestions,
    lb.TotalAnswers,
    lb.AverageViews,
    lb.HighestScore,
    rph.PostId,
    rph.ActionType,
    rph.CreationDate,
    rph.Comment
FROM Leaderboard lb
LEFT JOIN RecentPostHistory rph ON lb.UserId = rph.UserId
WHERE lb.Rank <= 10
ORDER BY lb.Reputation DESC, lb.TotalPosts DESC, rph.CreationDate DESC;