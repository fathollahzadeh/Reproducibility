
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostMetrics AS (
    SELECT 
        tp.Title,
        tp.PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.Id = c.PostId
    LEFT JOIN 
        Votes v ON tp.Id = v.PostId
    GROUP BY 
        tp.Title, tp.PostType
)
SELECT 
    pm.Title,
    pm.PostType,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    CASE 
        WHEN pm.UpVoteCount + pm.DownVoteCount > 0 
        THEN ROUND((pm.UpVoteCount * 1.0 / (pm.UpVoteCount + pm.DownVoteCount)) * 100, 2)
        ELSE 0 
    END AS UpVotePercentage
FROM 
    PostMetrics pm
ORDER BY 
    pm.CommentCount DESC, pm.UpVoteCount DESC;
