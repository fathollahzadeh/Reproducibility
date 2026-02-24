
WITH TagCounts AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId IN (1, 2)
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        AnswerCount,
        QuestionCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY AnswerCount DESC, QuestionCount DESC, BadgeCount DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    tt.Tag,
    tt.PostCount,
    ru.DisplayName AS TopUser,
    ru.AnswerCount,
    ru.QuestionCount,
    ru.BadgeCount
FROM 
    TopTags tt
INNER JOIN 
    RankedUsers ru ON ru.UserRank = 1
WHERE 
    tt.Rank <= 10  
ORDER BY 
    tt.PostCount DESC;
