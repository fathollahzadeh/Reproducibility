WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) / 3600) AS AvgPostAgeInHours
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 100  
    GROUP BY 
        u.Id, u.DisplayName
),
TagPostStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        AvgPostAgeInHours,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagPostStats
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalScore AS UserScore,
    tu.AvgPostAgeInHours AS AveragePostAge,
    tt.TagName AS TopTag,
    tt.PostCount AS TagPostCount,
    tt.TotalViews AS TagTotalViews
FROM 
    TopUsers tu
JOIN 
    TopTags tt ON tu.Rank = tt.Rank
WHERE 
    tu.Rank <= 10  
ORDER BY 
    tu.Rank;