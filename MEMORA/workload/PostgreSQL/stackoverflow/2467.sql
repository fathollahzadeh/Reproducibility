WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Ranking
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.Score,
        pm.Ranking,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        PostMetrics pm
    LEFT JOIN 
        Badges b ON pm.PostId = b.UserId AND b.Class = 1
    WHERE 
        pm.Ranking <= 10
)

SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.BadgeName,
    CASE 
        WHEN tp.Score > 100 THEN 'Highly Popular'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityLevel,
    CONCAT('https://stackoverflow.com/posts/', tp.PostId) AS PostLink
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;