WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
AverageScore AS (
    SELECT 
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserCount AS (
    SELECT 
        COUNT(*) AS TotalUsers
    FROM 
        Users
)

SELECT 
    pc.PostType,
    pc.PostCount,
    avg.AverageScore,
    uc.TotalUsers
FROM 
    PostCounts pc,
    AverageScore avg,
    UserCount uc;