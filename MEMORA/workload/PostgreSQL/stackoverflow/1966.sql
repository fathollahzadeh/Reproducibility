
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COALESCE(ROUND(AVG(v.BountyAmount), 2), 0) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
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
        TotalViews,
        TotalBadges,
        AvgBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalViews DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalViews,
    u.TotalBadges,
    u.AvgBounty,
    COALESCE(ROUND((CAST(u.TotalPosts AS decimal) / NULLIF(u.TotalViews, 0)) * 100, 2), 0) AS PostViewRatio,
    CASE 
        WHEN u.TotalBadges >= 5 THEN 'Experienced' 
        WHEN u.TotalBadges >= 3 THEN 'Moderate' 
        ELSE 'Novice' 
    END AS UserExperience,
    p.CreationDate,
    pt.Name AS PostType
FROM 
    TopUsers u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank, u.TotalViews DESC;
