
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        um.*,
        (TotalUpvotes - TotalDownvotes) AS VoteBalance,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserMetrics um
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.Reputation, 
    u.TotalPosts, 
    u.TotalQuestions, 
    u.TotalAnswers, 
    u.TotalComments, 
    u.TotalBadges, 
    u.VoteBalance,
    CASE 
        WHEN u.Rank <= 10 THEN 'Top Contributor'
        WHEN u.Rank <= 50 THEN 'Active Contributor'
        ELSE 'Casual Contributor'
    END AS ContributorType
FROM 
    TopUsers u
WHERE 
    u.TotalPosts > 0 
ORDER BY 
    u.VoteBalance DESC, 
    u.Reputation DESC;
