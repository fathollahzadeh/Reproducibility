WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        ua.TotalViews,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        RANK() OVER (ORDER BY ua.Reputation DESC, ua.TotalViews DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    CASE 
        WHEN tu.TotalUpvotes > tu.TotalDownvotes THEN 'Positive'
        WHEN tu.TotalUpvotes < tu.TotalDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS UserSentiment
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.Reputation DESC;

