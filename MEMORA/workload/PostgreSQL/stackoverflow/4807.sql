WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
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
        AvgViewCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Tags) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UsersWithPopularTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        pt.TagName
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    INNER JOIN 
        PopularTags pt ON p.Tags LIKE '%' || pt.TagName || '%'
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.AvgViewCount,
    array_agg(DISTINCT upt.TagName) AS TagsParticipatedIn,
    pt.UsageCount AS TagUsageCount
FROM 
    TopUsers tu
LEFT JOIN 
    UsersWithPopularTags upt ON tu.UserId = upt.UserId
LEFT JOIN 
    PopularTags pt ON upt.TagName = pt.TagName
WHERE 
    tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.TotalScore, tu.AvgViewCount, pt.UsageCount
ORDER BY 
    tu.TotalScore DESC;
