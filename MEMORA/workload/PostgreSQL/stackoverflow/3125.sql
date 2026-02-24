WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStatistics
),
ClosedPostStatistics AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalClosedPosts,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.UserId
),
FinalStatistics AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalQuestions,
        tu.TotalAnswers,
        tu.TotalBounty,
        COALESCE(cps.TotalClosedPosts, 0) AS TotalClosedPosts,
        cps.LastClosedDate
    FROM TopUsers tu
    LEFT JOIN ClosedPostStatistics cps ON tu.UserId = cps.UserId
)
SELECT 
    *,
    CASE 
        WHEN TotalClosedPosts > 0 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM FinalStatistics
WHERE TotalPosts > 5
ORDER BY TotalPosts DESC, TotalBounty DESC;