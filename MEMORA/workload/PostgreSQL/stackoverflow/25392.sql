WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        COUNT(DISTINCT COALESCE(c.UserId, p.OwnerUserId)) AS UniqueUsers,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        Tag
),
BadgeStats AS (
    SELECT 
        b.Name AS BadgeName,
        COUNT(DISTINCT b.UserId) AS UserCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        b.Name
),
CombinedStats AS (
    SELECT 
        ts.Tag,
        ts.QuestionCount,
        ts.AcceptedAnswerCount,
        ts.UniqueUsers,
        ts.AvgUserReputation,
        bs.BadgeName,
        bs.UserCount AS BadgeUserCount,
        bs.PostCount AS BadgePostCount
    FROM 
        TagStats ts
    LEFT JOIN 
        BadgeStats bs ON ts.UniqueUsers > 0  
)
SELECT 
    Tag,
    QuestionCount,
    AcceptedAnswerCount,
    UniqueUsers,
    AvgUserReputation,
    BadgeName,
    BadgeUserCount,
    BadgePostCount
FROM 
    CombinedStats
ORDER BY 
    QuestionCount DESC,
    UniqueUsers DESC;