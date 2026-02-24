
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags FROM 2 FOR length(p.Tags) - 2), '>')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS NumberOfQuestions
    FROM 
        Tags t
    JOIN 
        PostTags pt ON t.TagName = pt.Tag
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        NumberOfQuestions,
        RANK() OVER (ORDER BY NumberOfQuestions DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        NumberOfQuestions > 10 
),
MostPopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 5 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
BestAnswers AS (
    SELECT 
        p.AcceptedAnswerId AS AnswerId,
        p.Title AS AnswerTitle,
        u.DisplayName AS UserName,
        p.Score AS AnswerScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 
),
FinalResults AS (
    SELECT 
        tt.TagName,
        tp.Title AS QuestionTitle,
        tp.Score AS QuestionScore,
        tp.ViewCount AS QuestionViews,
        mp.AnswerId,
        mp.AnswerTitle,
        mp.UserName AS AnsweredBy,
        mp.AnswerScore AS AnswerScore
    FROM 
        TopTags tt
    JOIN 
        MostPopularPosts tp ON EXISTS (
            SELECT 1 FROM PostTags pt WHERE pt.PostId = tp.Id AND pt.Tag = tt.TagName
        )
    LEFT JOIN 
        BestAnswers mp ON tp.Id = (SELECT AcceptedAnswerId FROM Posts p WHERE p.Id = tp.Id)
)

SELECT 
    TagName,
    QuestionTitle,
    QuestionScore,
    QuestionViews,
    AnswerId,
    AnswerTitle,
    AnsweredBy,
    AnswerScore
FROM 
    FinalResults
ORDER BY 
    TagName, 
    QuestionScore DESC;
