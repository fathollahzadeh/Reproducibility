WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tp.PostId) AS HistoryCount
    FROM 
        TopRankedPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.HistoryCount,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate
FROM 
    TopRankedPosts tp
JOIN 
    PostStats ps ON tp.PostId = ps.PostId
ORDER BY 
    ps.VoteCount DESC, tp.Score DESC;