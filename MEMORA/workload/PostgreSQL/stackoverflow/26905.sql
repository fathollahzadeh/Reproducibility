
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpvotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        AcceptedQuestions,
        AverageUpvotes,
        AverageDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)

SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    ts.TotalPosts,
    ts.TotalQuestions,
    ts.TotalAnswers,
    ts.AcceptedQuestions,
    ts.AverageUpvotes,
    ts.AverageDownvotes
FROM 
    TopUsers ts
JOIN 
    Users u ON ts.UserId = u.Id
WHERE 
    ts.Rank <= 10
ORDER BY 
    ts.Rank;
