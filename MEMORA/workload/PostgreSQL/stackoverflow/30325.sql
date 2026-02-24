WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS Author,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostScores AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Author,
        ps.Upvotes,
        ps.Downvotes,
        COALESCE(CAST(o.ReportedCount AS INT), 0) AS ReportedCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (
            SELECT 
                PostId, 
                COUNT(*) AS ReportedCount
            FROM 
                Comments c
            WHERE 
                c.Text ILIKE '%spam%'
            GROUP BY 
                PostId
        ) o ON rp.PostId = o.PostId
    JOIN 
        PostScores ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.Score,
    tp.Upvotes,
    tp.Downvotes,
    tp.ReportedCount,
    tp.ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.Upvotes DESC;