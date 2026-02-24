WITH PostSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswerCount
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostCount DESC 
    LIMIT 10
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    au.DisplayName AS ActiveUser,
    au.PostCount AS UserPostCount
FROM 
    PostSummary ps
LEFT JOIN 
    ActiveUsers au ON true  
ORDER BY 
    ps.PostType;