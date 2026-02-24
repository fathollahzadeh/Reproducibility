
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalUpvotes,
        TotalDownvotes,
        AvgViewCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalUpvotes DESC) AS RankByUpvotes
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.AvgViewCount,
    (tu.RankByPosts + tu.RankByUpvotes) / 2.0 AS OverallRank
FROM 
    TopUsers tu
WHERE 
    tu.PostCount > 5
ORDER BY 
    OverallRank ASC
FETCH FIRST 10 ROWS ONLY;
