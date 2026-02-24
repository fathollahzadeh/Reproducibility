WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments 
    GROUP BY 
        PostId
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Votes 
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.OwnerDisplayName,
        COALESCE(pcc.CommentCount, 0) AS TotalComments,
        COALESCE(pvc.UpvoteCount, 0) AS TotalUpvotes,
        COALESCE(pvc.DownvoteCount, 0) AS TotalDownvotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostCommentCounts pcc ON tp.PostId = pcc.PostId
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostId = pvc.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    OwnerDisplayName,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;