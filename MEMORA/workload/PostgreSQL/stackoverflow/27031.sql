
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    tt.Tag AS MostPopularTag,
    tt.PostCount AS TagPostCount,
    tt.TotalViews AS TagTotalViews,
    tt.AverageScore AS TagAverageScore,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.QuestionCount AS TopUserQuestionCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.Tag = ANY (string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><'))
JOIN 
    TopUsers tu ON tu.UserRank <= 10
WHERE 
    rp.ScoreRank <= 10 
ORDER BY 
    rp.ScoreRank, tu.Reputation DESC;
