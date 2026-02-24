WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        r.Score,
        r.ViewCount,
        r.Tags,
        r.CommentCount,
        r.UpVotes,
        CASE 
            WHEN r.RankByDate <= 5 THEN 'Top 5 Recent Posts'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM 
        RankedPosts r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.Tags,
    COALESCE(path.RevisionCount, 0) AS RevisionCount
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
) path ON tp.PostId = path.PostId
WHERE 
    tp.CommentCount > 2 AND tp.UpVotes > 5
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;