WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        u.DisplayName AS Owner,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        Owner,
        COUNT(PostId) AS TotalQuestions,
        SUM(ViewCount) AS TotalViews,
        AVG(Reputation) AS AverageReputation
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 
    GROUP BY 
        Owner
),
TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    tu.Owner,
    tu.TotalQuestions,
    tu.TotalViews,
    tu.AverageReputation,
    tt.TagName,
    tt.TagCount
FROM 
    TopUsers tu
JOIN 
    TopTags tt ON tu.Owner IN (SELECT DISTINCT u.DisplayName FROM Users u JOIN Posts p ON u.Id = p.OwnerUserId WHERE p.Tags LIKE '%' || tt.TagName || '%')
ORDER BY 
    tu.TotalQuestions DESC, tu.AverageReputation DESC, tt.TagCount DESC;