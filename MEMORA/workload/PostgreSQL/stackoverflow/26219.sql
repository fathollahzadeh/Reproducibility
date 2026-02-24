WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighlightedAnswers AS (
    SELECT 
        a.Id AS AnswerId,
        a.Body,
        a.Score AS AnswerScore,
        a.CreationDate AS AnswerCreationDate,
        aq.QuestionId,
        ROW_NUMBER() OVER (PARTITION BY aq.QuestionId ORDER BY a.Score DESC) AS rn
    FROM 
        Posts a
    JOIN 
        RankedQuestions aq ON a.ParentId = aq.QuestionId
    WHERE 
        a.PostTypeId = 2 
),
TopAnswers AS (
    SELECT 
        QuestionId,
        AnswerId,
        Body,
        AnswerScore,
        AnswerCreationDate
    FROM 
        HighlightedAnswers
    WHERE 
        rn = 1
),
CombinedResults AS (
    SELECT 
        rq.QuestionId,
        rq.Title,
        rq.CreationDate AS QuestionCreationDate,
        rq.ViewCount,
        rq.Score AS QuestionScore,
        rq.OwnerDisplayName,
        ta.AnswerId,
        ta.Body AS TopAnswerBody,
        ta.AnswerScore,
        ta.AnswerCreationDate
    FROM 
        RankedQuestions rq
    LEFT JOIN 
        TopAnswers ta ON rq.QuestionId = ta.QuestionId
)
SELECT 
    cr.QuestionId,
    cr.Title AS QuestionTitle,
    cr.QuestionCreationDate,
    cr.ViewCount AS QuestionViewCount,
    cr.QuestionScore AS QuestionScore,
    cr.OwnerDisplayName,
    COALESCE(cr.TopAnswerBody, 'No answers yet') AS TopAnswerBody,
    COALESCE(cr.AnswerScore, 0) AS TopAnswerScore,
    cr.AnswerCreationDate AS TopAnswerCreationDate
FROM 
    CombinedResults cr
ORDER BY 
    cr.QuestionCreationDate DESC
LIMIT 20;