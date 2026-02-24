WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostInteraction AS (
    SELECT 
        tp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    GROUP BY 
        tp.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount
FROM 
    TopPosts tp
JOIN 
    PostInteraction pi ON tp.PostId = pi.PostId
ORDER BY 
    tp.Score DESC, pi.CommentCount DESC;