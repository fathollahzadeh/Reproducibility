
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.Score,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
ScoreTrends AS (
    SELECT 
        OwnerUserId,
        AVG(Score) AS AvgPostScore,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN AcceptedAnswerId IS NOT NULL THEN Id END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        s.AvgPostScore,
        s.TotalPosts,
        s.AcceptedAnswers,
        RANK() OVER (ORDER BY s.AvgPostScore DESC) AS Rank
    FROM 
        Users u
    JOIN 
        ScoreTrends s ON u.Id = s.OwnerUserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ph.Level, 0) AS MaxQuestionLevel,
    tu.AvgPostScore,
    tu.TotalPosts,
    tu.AcceptedAnswers
FROM 
    Users u
LEFT JOIN 
    PostHierarchy ph ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM PostLinks pl WHERE pl.RelatedPostId = u.Id) LIMIT 1)
JOIN 
    TopUsers tu ON u.Id = tu.Id
WHERE 
    u.Location IS NOT NULL
    AND u.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
ORDER BY 
    tu.Rank, u.Reputation DESC;
