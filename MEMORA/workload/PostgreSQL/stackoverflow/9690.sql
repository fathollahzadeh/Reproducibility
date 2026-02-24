WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.ClosedDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopOwnerPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        ClosedDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        OwnerRank = 1
),
DetailedPostStats AS (
    SELECT 
        t.PostId,
        t.Title,
        t.CreationDate,
        t.Score,
        t.ViewCount,
        t.AnswerCount,
        t.CommentCount,
        t.ClosedDate,
        t.OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        TopOwnerPosts t
    LEFT JOIN 
        Comments c ON t.PostId = c.PostId
    LEFT JOIN 
        Votes v ON t.PostId = v.PostId
    GROUP BY 
        t.PostId, t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount, t.CommentCount, t.ClosedDate, t.OwnerDisplayName
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    ClosedDate,
    OwnerDisplayName,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes
FROM 
    DetailedPostStats
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 10;