WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Anonymous') AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.Score,
        rp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS Deletions
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Owner, rp.Score, rp.ViewCount
),
TopPosts AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.Rank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts p
)
SELECT 
    ps.*,
    tp.PostCategory,
    CASE 
        WHEN ps.Deletions > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS Status
FROM 
    PostStatistics ps
JOIN 
    TopPosts tp ON ps.PostId = tp.PostId
WHERE 
    (ps.CommentCount > 0 OR ps.UpVotes > 0)
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;