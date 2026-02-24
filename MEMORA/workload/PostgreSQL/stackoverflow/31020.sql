
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(v.VoteCount, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostUpdates AS (
    SELECT 
        p.Id,
        p.Title,
        MAX(ph.Level) AS MaxLevel,
        COUNT(DISTINCT ph.Title) AS UniqueHierarchyTitles
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.Id
    GROUP BY 
        p.Id, p.Title
),
FeaturedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AvgScore,
    p.Title AS PostTitle,
    pu.MaxLevel,
    pu.UniqueHierarchyTitles,
    fu.UserRank
FROM 
    UserPostStats u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
JOIN 
    PostUpdates pu ON p.Id = pu.Id
LEFT JOIN 
    FeaturedUsers fu ON u.UserId = fu.UserId
WHERE 
    pu.MaxLevel > 0 AND
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 0
ORDER BY 
    u.AvgScore DESC, u.TotalPosts DESC
LIMIT 10;
