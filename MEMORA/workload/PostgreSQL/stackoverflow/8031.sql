WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
ActiveTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
TopTags AS (
    SELECT 
        TagName,
        ActivePostCount,
        RANK() OVER (ORDER BY ActivePostCount DESC) AS TagRank
    FROM 
        ActiveTags
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.BadgeCount,
    tt.TagName AS PopularTag,
    tt.ActivePostCount
FROM 
    TopUsers tu
JOIN 
    TopTags tt ON tu.ReputationRank < 11 AND tt.TagRank < 11
ORDER BY 
    tu.Reputation DESC, tt.ActivePostCount DESC;
