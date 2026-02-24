WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
          AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
),

TopAnswers AS (
    SELECT 
        a.Id AS AnswerId,
        a.ParentId AS QuestionId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts a
    LEFT JOIN 
        Comments c ON a.Id = c.PostId
    LEFT JOIN 
        Votes v ON a.Id = v.PostId
    WHERE 
        a.PostTypeId = 2 
    GROUP BY 
        a.Id
),

PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(ta.CommentCount, 0) AS AnswerCommentCount,
        COALESCE(ta.UpVotes, 0) AS AnswerUpVotes,
        COALESCE(ta.DownVotes, 0) AS AnswerDownVotes,
        rp.Rank,
        rp.CreationDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopAnswers ta ON rp.PostId = ta.QuestionId
)

SELECT 
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCommentCount,
    ps.AnswerUpVotes,
    ps.AnswerDownVotes,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - ps.CreationDate)) AS AgeInSeconds
FROM 
    PostStats ps
WHERE 
    ps.Rank = 1 
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 10;