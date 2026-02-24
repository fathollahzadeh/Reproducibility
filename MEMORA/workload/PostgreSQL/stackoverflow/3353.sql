WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.Rank,
        CASE 
            WHEN ps.Rank <= 10 THEN 'Top Ranked'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        PostStats ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.CommentCount,
    tp.PostCategory,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 6) THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    (tp.Rank <= 10 OR tp.CommentCount > 5)
ORDER BY 
    tp.Rank, tp.ViewCount DESC
LIMIT 50;