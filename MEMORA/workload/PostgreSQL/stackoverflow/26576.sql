WITH TagUsage AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '>')) AS Tag,
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        PostTypeId = 1 
),
TopTags AS (
    SELECT 
        Tag, 
        COUNT(PostId) AS UsageCount
    FROM 
        TagUsage
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        STRING_AGG(t.Tag, ', ') AS RelatedTags
    FROM 
        Posts p
    JOIN 
        TagUsage t ON p.Id = t.PostId
    WHERE 
        t.Tag IN (SELECT Tag FROM TopTags)
    GROUP BY 
        p.Id
    HAVING 
        COUNT(t.Tag) > 1 
    ORDER BY 
        p.ViewCount DESC
    LIMIT 5
)
SELECT 
    q.QuestionId,
    q.Title,
    q.ViewCount,
    q.AnswerCount,
    q.CommentCount,
    q.CreationDate,
    q.RelatedTags,
    ROUND((EXTRACT(EPOCH FROM cast('2024-10-01 12:34:56' as timestamp) - q.CreationDate) / 86400), 2) AS AgeInDays
FROM 
    PopularQuestions q
ORDER BY 
    q.ViewCount DESC;