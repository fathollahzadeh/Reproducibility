
WITH TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT v.UserId) AS VoterCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
TagStats AS (
    SELECT 
        TagName,
        PostCount,
        AnswerCount,
        VoterCount,
        ROUND((AnswerCount::FLOAT / NULLIF(PostCount, 0)) * 100, 2) AS AnswerRate, 
        ROUND((VoterCount::FLOAT / NULLIF(PostCount, 0)) * 100, 2) AS VoterEngagement
    FROM 
        TagUsage
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AnswerCount,
        VoterCount,
        AnswerRate,
        VoterEngagement,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.AnswerCount,
    tt.VoterCount,
    tt.AnswerRate,
    tt.VoterEngagement
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.PostCount DESC;
