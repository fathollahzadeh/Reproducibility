
WITH PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.ViewCount,
        pa.CommentCount,
        pa.VoteCount,
        pa.UpVotes,
        pa.DownVotes,
        RANK() OVER (ORDER BY pa.Score DESC, pa.ViewCount DESC) AS Rank
    FROM 
        PostAggregates pa
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.UpVotes,
    tp.DownVotes
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.Rank;
