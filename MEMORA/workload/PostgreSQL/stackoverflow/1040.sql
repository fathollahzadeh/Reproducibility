WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AverageScore,
        TotalBounty,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    COALESCE(tu.AverageScore, 0) AS AverageScore,
    COALESCE(tu.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN tu.LastPostDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus
FROM 
    TopUsers tu
WHERE 
    tu.PostRank <= 10
ORDER BY 
    tu.TotalPosts DESC;