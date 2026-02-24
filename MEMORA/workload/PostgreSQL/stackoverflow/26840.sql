
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagSplit AS (
    SELECT 
        rp.PostId,
        UNNEST(string_to_array(rp.Tags, '><')) AS Tag, 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score
    FROM 
        RankedPosts rp
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        ts.Tag,
        COUNT(ts.PostId) AS TagCount
    FROM 
        TagSplit ts
    GROUP BY 
        ts.Tag
    HAVING 
        COUNT(ts.PostId) > 10 
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalViews,
        us.AvgScore,
        ROW_NUMBER() OVER (ORDER BY us.TotalViews DESC) AS ViewRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.QuestionCount,
    tu.TotalViews,
    tu.AvgScore,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON tu.QuestionCount > 5 
ORDER BY 
    tu.QuestionCount DESC, 
    pt.TagCount DESC;
