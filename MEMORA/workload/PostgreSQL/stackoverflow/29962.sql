
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
CombinedStats AS (
    SELECT 
        ru.Owner,
        ru.PostId,
        ru.Title,
        ru.CreationDate,
        ru.Score AS QuestionScore,
        ts.PostCount AS TagCount,
        tu.QuestionCount AS UserQuestionCount,
        tu.TotalViews,
        tu.TotalScore
    FROM 
        RankedPosts ru
    LEFT JOIN 
        TagStats ts ON ts.Tag = ANY (string_to_array(substring(ru.Tags, 2, length(ru.Tags)-2), '><'))
    LEFT JOIN 
        TopUsers tu ON ru.Owner = tu.DisplayName
)
SELECT 
    Owner,
    COUNT(PostId) AS TotalPosts,
    AVG(QuestionScore) AS AverageScore,
    COUNT(DISTINCT TagCount) AS TotalUniqueTags,
    SUM(UserQuestionCount) AS TotalQuestionsByUser,
    SUM(TotalViews) AS TotalViewsByUser,
    AVG(TotalScore) AS AverageUserScore
FROM 
    CombinedStats
GROUP BY 
    Owner
ORDER BY 
    TotalPosts DESC
LIMIT 5;
