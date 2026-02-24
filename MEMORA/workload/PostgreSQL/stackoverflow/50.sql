WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
),
TopAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        a.Body,
        a.CreationDate,
        a.Score,
        COALESCE(u.DisplayName, 'Anonymous') AS AuthorDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Users u ON a.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    tq.Title AS QuestionTitle,
    tq.CreationDate AS QuestionDate,
    tq.Score AS QuestionScore,
    tq.ViewCount AS QuestionViews,
    tq.CommentCount AS QuestionComments,
    tq.OwnerDisplayName AS QuestionOwner,
    ta.Body AS AcceptedAnswerBody,
    ta.CreationDate AS AnswerDate,
    ta.Score AS AnswerScore,
    ta.AuthorDisplayName AS AnswerAuthor,
    ta.UpVoteCount
FROM 
    TopQuestions tq
LEFT JOIN 
    TopAnswers ta ON tq.PostId = ta.AnswerId
ORDER BY 
    tq.Score DESC, ta.UpVoteCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;