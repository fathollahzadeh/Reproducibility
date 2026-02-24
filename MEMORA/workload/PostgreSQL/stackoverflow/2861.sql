
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 50
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounties,
        AverageReputation,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM UserActivity
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseEvent
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
)
SELECT 
    tu.DisplayName AS User,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBounties,
    cp.Title AS ClosedPostTitle,
    cp.CloseDate,
    cp.ClosedBy,
    CASE 
        WHEN tu.TotalPosts > 100 THEN 'Highly Active'
        WHEN tu.TotalPosts BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM TopUsers tu
LEFT JOIN ClosedPosts cp ON tu.DisplayName = cp.ClosedBy
ORDER BY tu.Rank, tu.TotalPosts DESC;
