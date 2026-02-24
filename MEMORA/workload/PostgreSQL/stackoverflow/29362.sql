WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankByScore,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1 
),

QuestionStatistics AS (
    SELECT 
        TagName,
        COUNT(PostId) AS QuestionCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        TagName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
)

SELECT 
    qs.TagName,
    qs.QuestionCount,
    qs.TotalViews,
    qs.AvgScore,
    qs.AvgAnswerCount,
    tq.Title AS TopQuestionTitle,
    tq.CreationDate AS TopQuestionDate,
    tq.Author AS TopQuestionAuthor
FROM 
    QuestionStatistics qs
LEFT JOIN 
    TopQuestions tq ON qs.TagName = tq.TagName
ORDER BY 
    qs.QuestionCount DESC, 
    qs.TotalViews DESC;