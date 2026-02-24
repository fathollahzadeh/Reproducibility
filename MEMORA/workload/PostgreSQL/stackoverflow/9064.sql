
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalQuestions,
        ue.TotalAnswers,
        ue.TotalUpvotes,
        ue.TotalDownvotes,
        ue.TotalBadges,
        RANK() OVER (ORDER BY ue.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY ue.TotalUpvotes DESC) AS UpvoteRank
    FROM 
        UserEngagement ue
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.TotalBadges,
    tu.PostRank,
    tu.UpvoteRank
FROM 
    TopUsers tu
WHERE 
    tu.PostRank <= 10 
    OR tu.UpvoteRank <= 10
ORDER BY 
    tu.PostRank, tu.UpvoteRank;
