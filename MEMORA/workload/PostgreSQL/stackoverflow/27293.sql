WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS QuestionCount,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS AnswerCount
    FROM 
        Tags AS t
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserReputation AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users AS u
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    u.DisplayName AS TopUserDisplayName,
    u.Reputation AS TopUserReputation,
    u.UserRank
FROM 
    TopTags AS t
JOIN 
    UserReputation AS u ON u.UserRank <= 5
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank, u.Reputation DESC;
