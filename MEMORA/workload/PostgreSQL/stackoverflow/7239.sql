WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5  
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.AnswerCount,
        tp.CommentCount,
        tp.FavoriteCount,
        tp.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
        tp.OwnerDisplayName, tp.AnswerCount, tp.CommentCount, tp.FavoriteCount, tp.Tags
)
SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.FavoriteCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.Tags,
    CAST(pm.CreationDate AS DATE) AS CreatedOn
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC;