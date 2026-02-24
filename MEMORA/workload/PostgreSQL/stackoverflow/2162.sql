
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.LastActivityDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month') THEN 1 ELSE 0 END) AS RecentActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        RecentActivity,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStatistics
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        RecentActivity
    FROM 
        RankedUsers
    WHERE 
        PostRank <= 10
),
CloseReasonStatistics AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    COALESCE(cr.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cr.CloseReasons, 'None') AS CloseReasons,
    CASE 
        WHEN tu.RecentActivity > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS ActivityStatus
FROM 
    TopUsers tu
LEFT JOIN 
    CloseReasonStatistics cr ON tu.UserId = cr.UserId
ORDER BY 
    tu.TotalPosts DESC;
