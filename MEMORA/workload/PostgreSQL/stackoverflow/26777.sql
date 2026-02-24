WITH TagFrequency AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
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
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 1 
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Tags,
        t.Tag
    FROM 
        Posts p
    JOIN 
        TopTags t ON t.Tag = ANY(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    pq.QuestionId,
    pq.Title,
    pq.ViewCount,
    pq.AnswerCount,
    pq.CreationDate,
    STRING_AGG(DISTINCT pq.Tag, ', ') AS Tags
FROM 
    PopularQuestions pq
GROUP BY 
    pq.QuestionId, 
    pq.Title, 
    pq.ViewCount, 
    pq.AnswerCount, 
    pq.CreationDate
ORDER BY 
    pq.ViewCount DESC;