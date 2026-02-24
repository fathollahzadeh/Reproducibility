WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        LastPostDate,
        ScoreRank
    FROM UserPostStats
    WHERE ScoreRank <= 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        ph.PostHistoryTypeId,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    tu.TotalViews,
    tu.LastPostDate,
    rph.Title AS PostTitle,
    rph.UserDisplayName AS EditorName,
    rph.Comment AS EditComment,
    rph.Text AS NewValue,
    rph.PostHistoryTypeId
FROM TopUsers tu
JOIN RecentPostHistory rph ON rph.PostId IN (
    SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId
) AND rph.rn = 1
ORDER BY tu.ScoreRank;