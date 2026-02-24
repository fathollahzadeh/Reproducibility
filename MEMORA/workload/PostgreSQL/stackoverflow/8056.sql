WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AverageViews,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
)
SELECT 
    t.DisplayName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalScore,
    t.AverageViews,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers t
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON t.UserId = b.UserId
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.TotalScore DESC, 
    t.PostCount DESC;
