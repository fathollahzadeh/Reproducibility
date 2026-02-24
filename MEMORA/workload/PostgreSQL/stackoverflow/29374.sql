WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TagPostCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(LENGTH(p.Body) - LENGTH(REPLACE(p.Body, ' ', ''))) + COUNT(p.Id) AS TotalWordCount 
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%<' || t.TagName || '>' || '%' 
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalWordCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalWordCount DESC) AS rn
    FROM 
        TagPostCounts
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.LastPostDate,
    tt.TagName,
    tt.PostCount,
    tt.TotalWordCount
FROM 
    UserPostStats ups
JOIN 
    TopTags tt ON tt.rn <= 5 
WHERE 
    ups.TotalPosts > 20 
ORDER BY 
    ups.TotalScore DESC, 
    ups.LastPostDate DESC;