WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND pt.Name = 'Question'
),

TopQuestions AS (
    SELECT 
        PostRank,
        PostId,
        Title,
        CreationDate,
        ViewCount,
        AnswerCount,
        CommentCount,
        Body,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10 
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.AnswerCount,
    tq.CommentCount,
    tq.OwnerDisplayName,
    COUNT(c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
FROM 
    TopQuestions tq
LEFT JOIN 
    Comments c ON tq.PostId = c.PostId
LEFT JOIN 
    Votes v ON tq.PostId = v.PostId
GROUP BY 
    tq.PostId, tq.Title, tq.CreationDate, tq.ViewCount, tq.AnswerCount, tq.CommentCount, tq.OwnerDisplayName
ORDER BY 
    tq.ViewCount DESC;