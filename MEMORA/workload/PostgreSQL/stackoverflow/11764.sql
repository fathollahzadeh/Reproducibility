WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    TotalPostScore,
    CommentCount,
    CASE 
        WHEN PostCount > 0 THEN TotalPostScore / PostCount 
        ELSE 0 
    END AS AvgPostScore
FROM 
    UserStats
ORDER BY 
    PostCount DESC, AvgPostScore DESC;