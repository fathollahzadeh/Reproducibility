
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostStats AS (
    SELECT 
        th.PostId,
        th.Title,
        th.CreationDate,
        th.Score,
        th.ViewCount,
        th.AnswerCount,
        th.OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        TopPosts th
    LEFT JOIN 
        Comments c ON th.PostId = c.PostId
    LEFT JOIN 
        Votes v ON th.PostId = v.PostId
    GROUP BY 
        th.PostId, th.Title, th.CreationDate, th.Score, th.ViewCount, th.AnswerCount, th.OwnerReputation
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.OwnerReputation,
    ROUND((CAST(ps.UpVotes AS FLOAT) / NULLIF(ps.UpVotes + ps.DownVotes, 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 50;
