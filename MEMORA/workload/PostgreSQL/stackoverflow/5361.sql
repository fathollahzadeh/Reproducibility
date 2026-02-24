
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostStats
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    mu.DisplayName,
    mu.PostCount,
    mu.QuestionCount,
    mu.AnswerCount,
    mu.AverageScore,
    tt.TagName,
    tt.UsageCount
FROM 
    MostActiveUsers mu
CROSS JOIN 
    TopTags tt
WHERE 
    mu.UserRank <= 10
ORDER BY 
    mu.PostCount DESC, 
    tt.UsageCount DESC;
