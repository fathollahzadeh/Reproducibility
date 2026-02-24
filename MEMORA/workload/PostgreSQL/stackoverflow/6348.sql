
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
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
        TotalPosts,
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
        TagName,
        COUNT(*) AS TagCount
    FROM 
        (SELECT TRIM(unnest(string_to_array(Tags, '<>'))) AS TagName FROM Posts) AS TagsList
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        PopularTags
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.AvgViewCount,
    tt.TagName,
    tt.TagCount
FROM 
    TopUsers tu
JOIN 
    TopTags tt ON tu.QuestionCount > 10 AND tu.AnswerCount > 30
WHERE 
    tu.ScoreRank <= 10 AND tt.TagRank <= 5
ORDER BY 
    tu.TotalScore DESC, tt.TagCount DESC;
