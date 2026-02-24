WITH PostTypeStats AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS UserPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    pts.PostTypeName,
    pts.PostCount,
    pts.AverageScore,
    (SELECT COUNT(*) FROM UserPostCounts) AS TotalUsers
FROM 
    PostTypeStats pts
ORDER BY 
    pts.PostCount DESC;