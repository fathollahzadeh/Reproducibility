WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalComments, 
        TotalBounty, 
        TotalUpvotes, 
        TotalDownvotes,
        Rank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    COALESCE(tu.TotalComments, 0) AS TotalComments,
    COALESCE(tu.TotalBounty, 0) AS TotalBounty,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    CASE 
        WHEN tu.TotalPosts < 50 THEN 'Newbie'
        WHEN tu.TotalPosts BETWEEN 50 AND 200 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalPosts DESC;