WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount
    FROM 
        Users u
    JOIN 
        UserPostCounts up ON u.Id = up.UserId
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    ORDER BY 
        u.LastAccessDate DESC
    LIMIT 100
),
PopularTags AS (
    SELECT 
        t.TagName,
        t.Count
    FROM 
        Tags t
    ORDER BY 
        t.Count DESC
    LIMIT 10
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    pt.TagName,
    pt.Count AS TagUsage
FROM 
    RecentActiveUsers ru
CROSS JOIN 
    PopularTags pt;