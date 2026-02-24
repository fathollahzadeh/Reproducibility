WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredQuestions,
        COUNT(b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        um.DisplayName,
        um.QuestionCount,
        um.PositiveScoredQuestions,
        um.NegativeScoredQuestions,
        um.BadgesCount,
        ROW_NUMBER() OVER (ORDER BY um.QuestionCount DESC, um.PositiveScoredQuestions DESC) AS Rank
    FROM 
        UserMetrics um
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.QuestionCount,
    tu.PositiveScoredQuestions,
    tu.NegativeScoredQuestions,
    tu.BadgesCount,
    tg.Tag,
    tg.UsageCount
FROM 
    TopUsers tu
JOIN 
    TagUsage tg ON tg.UsageCount = (SELECT MAX(UsageCount) FROM TagUsage)
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, tg.Tag;
