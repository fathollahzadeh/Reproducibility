WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
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
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStats AS (
    SELECT 
        tp.Id,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.Id = c.PostId
    LEFT JOIN 
        Votes v ON tp.Id = v.PostId
    GROUP BY 
        tp.Id, tp.Title, tp.OwnerDisplayName, tp.Score
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    CASE 
        WHEN ps.VoteCount > 100 THEN 'Highly Engaged'
        WHEN ps.VoteCount BETWEEN 51 AND 100 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC;