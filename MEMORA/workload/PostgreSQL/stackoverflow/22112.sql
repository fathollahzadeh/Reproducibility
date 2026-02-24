WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN ph.Comment IS NOT NULL THEN ph.Id END) AS EditCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
top_posts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount,
        Rank,
        CommentCount,
        UpVotes,
        DownVotes,
        EditCount
    FROM 
        ranked_posts
    WHERE 
        Rank <= 3
),
deleted_comments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS DeletedCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId AND c.UserId IS NULL  
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.EditCount,
    COALESCE(dc.DeletedCommentCount, 0) AS DeletedCommentCount,
    CASE 
        WHEN tp.UpVotes IS NULL OR tp.UpVotes = 0 THEN 'No upvotes'
        WHEN tp.DownVotes IS NULL OR tp.DownVotes = 0 THEN 'No downvotes'
        ELSE 'Active Participation' 
    END AS ParticipationStatus,
    CASE 
        WHEN tp.ViewCount > 1000 THEN 'Trending'
        WHEN tp.ViewCount > 500 THEN 'Popular'
        ELSE 'Lesser Known' 
    END AS PopularityLabel
FROM 
    top_posts tp
LEFT JOIN 
    deleted_comments dc ON tp.PostId = dc.PostId
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;