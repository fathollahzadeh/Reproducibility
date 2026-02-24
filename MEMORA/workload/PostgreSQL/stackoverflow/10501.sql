
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    COALESCE(SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalPostEdits
FROM 
    UserStats us
LEFT JOIN 
    PostHistory ph ON us.UserId = ph.UserId
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.TotalPosts, us.TotalQuestions, us.TotalAnswers, us.TotalUpvotes, us.TotalDownvotes
ORDER BY 
    us.Reputation DESC;
