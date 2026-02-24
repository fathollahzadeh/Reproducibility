
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        PostID,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 AND PostTypeId = 1
),
TopAnswers AS (
    SELECT 
        p.Id AS AnswerID,
        p.Title,
        u.DisplayName AS AnswererDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT Title FROM Posts WHERE Id = p.AcceptedAnswerId) AS AcceptedQuestionTitle
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL
)
SELECT 
    tq.Title AS QuestionTitle,
    tq.OwnerDisplayName AS QuestionOwner,
    tq.CreationDate AS QuestionCreationDate,
    tq.ViewCount AS QuestionViewCount,
    tq.Score AS QuestionScore,
    ta.AnswererDisplayName AS AcceptedAnswerer,
    ta.CreationDate AS AnswerCreationDate,
    ta.ViewCount AS AnswerViewCount,
    ta.Score AS AnswerScore,
    ta.AcceptedQuestionTitle
FROM 
    TopQuestions tq
LEFT JOIN 
    TopAnswers ta ON tq.Title = ta.AcceptedQuestionTitle
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
