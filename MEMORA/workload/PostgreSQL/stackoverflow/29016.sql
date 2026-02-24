
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate 
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.LastPostDate,
        ur.DisplayName AS MostActiveUser,
        (ur.Upvotes - ur.Downvotes) AS ReputationChange
    FROM 
        TagStats ts
    JOIN 
        UserReputation ur ON ur.Upvotes > ur.Downvotes
    WHERE 
        ts.PostCount > 10 
    ORDER BY 
        ts.PostCount DESC
    LIMIT 5
)

SELECT 
    pt.TagName,
    pt.PostCount,
    pt.QuestionCount,
    pt.AnswerCount,
    pt.LastPostDate,
    pt.MostActiveUser,
    pt.ReputationChange 
FROM 
    PopularTags pt
WHERE 
    pt.ReputationChange > 5
ORDER BY 
    pt.ReputationChange DESC;
