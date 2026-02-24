WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.ViewCount) DESC) AS ViewRank 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        PositivePosts,
        NegativePosts,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS OverallRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositivePosts,
    tu.NegativePosts,
    tu.TotalViews,
    ps.Title,
    ps.ViewCount,
    ps.CreationDate
FROM 
    TopUsers tu
LEFT JOIN 
    PostStatistics ps ON tu.UserId = ps.OwnerUserId
WHERE 
    ps.PostRank <= 3
ORDER BY 
    tu.OverallRank, ps.ViewCount DESC;