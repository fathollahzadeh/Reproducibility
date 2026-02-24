WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.Score > 0 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.Score IS NOT NULL AND p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS TotalAcceptedAnswers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.DisplayName
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    pc.TotalQuestions,
    pc.TotalAcceptedAnswers,
    ua.DisplayName,
    ua.PostsCount,
    ua.TotalBounty
FROM 
    PostCounts pc
LEFT JOIN 
    UserActivity ua ON ua.PostsCount > 0
ORDER BY 
    pc.TotalPosts DESC, ua.PostsCount DESC;