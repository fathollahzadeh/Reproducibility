WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS PostCount, 
        AVG(p.Score) AS AvgScore, 
        AVG(CASE WHEN pt.Id = 1 THEN p.AnswerCount ELSE NULL END) AS AvgAnswersPerQuestion 
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
BadgeStatistics AS (
    SELECT 
        b.Class,
        COUNT(DISTINCT b.UserId) AS UserCount
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2, 3)  
    GROUP BY 
        b.Class
)

SELECT 
    ps.PostType, 
    ps.PostCount, 
    ps.AvgScore, 
    ps.AvgAnswersPerQuestion,
    COALESCE(bs.UserCount, 0) AS UsersWithBadges
FROM 
    PostStatistics ps
LEFT JOIN 
    BadgeStatistics bs ON ps.PostType = 'Question'  
ORDER BY 
    ps.PostType;