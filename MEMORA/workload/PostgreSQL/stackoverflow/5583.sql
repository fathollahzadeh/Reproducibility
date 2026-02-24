WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
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
        Owner, 
        CreationDate, 
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.Title,
    tp.Owner,
    tp.CreationDate,
    tp.Score,
    pv.Upvotes,
    pv.Downvotes,
    cc.CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pv ON tp.PostId = pv.PostId
LEFT JOIN 
    CommentCounts cc ON tp.PostId = cc.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;