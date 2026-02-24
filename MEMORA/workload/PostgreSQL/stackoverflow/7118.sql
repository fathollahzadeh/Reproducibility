
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, CreationDate, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
)
SELECT 
    tp.Title, 
    tp.OwnerDisplayName, 
    tp.Score, 
    tp.CommentCount,
    (tp.UpVotes - tp.DownVotes) AS NetVotes,
    CASE 
        WHEN tp.Score >= 100 THEN 'High Performer'
        WHEN tp.Score BETWEEN 50 AND 99 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
