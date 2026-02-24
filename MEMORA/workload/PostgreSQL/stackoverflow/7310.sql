
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
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
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes,
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpvotes DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.TotalPosts,
    r.TotalQuestions,
    r.TotalAnswers,
    r.TotalUpvotes,
    r.TotalDownvotes,
    CASE 
        WHEN r.TotalPosts = 0 THEN 0 
        ELSE ROUND((CAST(r.TotalUpvotes AS decimal) / NULLIF(r.TotalPosts, 0)) * 100, 2) 
    END AS UpvotePercentage,
    CASE 
        WHEN r.TotalPosts = 0 THEN 0 
        ELSE ROUND((CAST(r.TotalDownvotes AS decimal) / NULLIF(r.TotalPosts, 0)) * 100, 2) 
    END AS DownvotePercentage,
    r.UserRank
FROM 
    RankedUsers r
WHERE 
    r.UserRank <= 10
ORDER BY 
    r.UserRank;
