WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

BadgeStats AS (
    SELECT 
        COUNT(DISTINCT b.UserId) AS UniqueUsersWithBadges
    FROM 
        Badges b
)

SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AverageScore,
    bs.UniqueUsersWithBadges
FROM 
    PostStats ps,
    BadgeStats bs
ORDER BY 
    ps.PostType;