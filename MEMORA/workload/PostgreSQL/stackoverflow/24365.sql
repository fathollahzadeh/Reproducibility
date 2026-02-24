WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        Rank,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.Score > 0 THEN 'Active' 
        WHEN tp.Score IS NULL THEN 'No score'
        ELSE 'Not Active' 
    END AS PostStatus,
    SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY tp.PostId) AS CommentCount,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM Tags tag 
     INNER JOIN Posts p ON tag.ExcerptPostId = p.Id 
     WHERE p.Id = tp.PostId
    ) AS TagsList
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
WHERE 
    tp.UpVoteCount > 0 OR tp.DownVoteCount > 0
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10
OFFSET 0;