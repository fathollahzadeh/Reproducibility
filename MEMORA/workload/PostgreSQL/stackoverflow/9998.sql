WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        p.OwnerUserId
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalStats AS (
    SELECT 
        ps.OwnerUserId,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalScore,
        ps.TotalViews,
        ps.LatestPostDate,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        PostStats ps
    LEFT JOIN 
        BadgeCounts bc ON ps.OwnerUserId = bc.UserId
)
SELECT 
    u.DisplayName,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.TotalScore,
    fs.TotalViews,
    fs.LatestPostDate,
    fs.BadgeCount
FROM 
    FinalStats fs
JOIN 
    Users u ON fs.OwnerUserId = u.Id
ORDER BY 
    fs.TotalScore DESC, fs.QuestionCount DESC
LIMIT 10;
