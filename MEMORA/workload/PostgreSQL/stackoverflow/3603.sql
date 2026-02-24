
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        PositivePosts,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositivePosts,
    tu.AverageScore,
    rp.Title,
    rp.Comment AS LatestComment,
    ph.Comment AS ReasonForClosure
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rp ON tu.UserId = rp.PostId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalPosts DESC;
