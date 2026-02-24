
WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),

RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteSum,
        SUM(COALESCE(c.Score, 0)) AS CommentScores
    FROM 
        Votes v
    LEFT JOIN 
        Comments c ON v.PostId = c.PostId
    WHERE 
        v.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)

SELECT 
    q.QuestionId,
    q.Title,
    q.CreationDate,
    q.AnswerCount,
    q.AverageUpVotes,
    COALESCE(rv.CommentCount, 0) AS TotalComments,
    COALESCE(rv.VoteSum, 0) AS TotalVotes,
    COALESCE(rv.CommentScores, 0) AS TotalCommentScores,
    CASE 
        WHEN q.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    RankedQuestions q
LEFT JOIN 
    RecentVotes rv ON q.QuestionId = rv.PostId
LEFT JOIN 
    Users u ON q.AnswerCount > 0 AND u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = q.AcceptedAnswerId)
WHERE 
    q.rn = 1 
    AND (rv.VoteSum IS NULL OR rv.VoteSum > 0 OR q.AnswerCount > 0)
ORDER BY 
    q.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
