WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
PostStats AS (
    SELECT 
        p.Id,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT vh.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN vh.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vh.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vh ON p.Id = vh.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.UpVotes - ps.DownVotes AS NetVotes,
    COALESCE(CAST(ROUND(ps.UpVotes::numeric / NULLIF(ps.VoteCount, 0) * 100, 2) AS VARCHAR), '0.00%') AS VotePercentage
FROM 
    TopPosts tp
JOIN 
    PostStats ps ON tp.PostId = ps.Id
WHERE 
    tp.ViewCount > 100
ORDER BY 
    tp.ViewCount DESC 
LIMIT 10;