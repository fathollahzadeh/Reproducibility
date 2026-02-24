
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(COALESCE(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 60, 0)) AS AvgResponseTime
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        u.Reputation > 100 AND u.CreationDate < CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        TotalBounty, 
        AvgResponseTime,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalBounty DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalBounty,
    tu.AvgResponseTime,
    CASE 
        WHEN tu.Rank <= 5 THEN 'Top Contributor'
        WHEN tu.Rank > 5 AND tu.Rank <= 10 THEN 'Notable Contributor'
        ELSE 'Regular User'
    END AS UserLevel
FROM 
    TopUsers tu
WHERE 
    tu.TotalPosts > 5
ORDER BY 
    tu.Rank;
