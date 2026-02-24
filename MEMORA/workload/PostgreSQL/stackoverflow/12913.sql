WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.TotalViews,
    ups.AcceptedAnswers,
    ptc.PostType,
    ptc.PostCount AS PostTypeCount
FROM 
    UserPostStats ups
JOIN 
    PostTypeCounts ptc ON ups.PostCount > 0
ORDER BY 
    ups.TotalScore DESC, ups.PostCount DESC
LIMIT 100;