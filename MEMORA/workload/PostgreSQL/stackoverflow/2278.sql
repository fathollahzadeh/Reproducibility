WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score IS NOT NULL
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
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.*,
        pvc.Upvotes,
        pvc.Downvotes,
        pc.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    COALESCE(tp.ViewCount, 0) AS ViewCount,
    COALESCE(tp.Upvotes, 0) AS Upvotes,
    COALESCE(tp.Downvotes, 0) AS Downvotes,
    COALESCE(tp.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN tp.Score > 10 THEN 'High Score'
        WHEN tp.Score BETWEEN 5 AND 10 THEN 'Medium Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;