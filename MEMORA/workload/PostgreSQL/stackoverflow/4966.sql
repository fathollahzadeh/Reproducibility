WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, Score, CommentCount, UpVotes, DownVotes,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostAnalytics
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.ScoreRank <= 10 THEN 'Top Post'
        ELSE 'Regular Post' 
    END AS PostCategory,
    COALESCE(pht.Comment, 'No comments') AS LastEditComment
FROM 
    Users u
JOIN 
    Posts p ON p.OwnerUserId = u.Id
RIGHT JOIN 
    TopPosts tp ON tp.PostId = p.Id
LEFT JOIN 
    PostHistory pht ON pht.PostId = p.Id AND pht.CreationDate = (
        SELECT 
            MAX(CreationDate) 
        FROM 
            PostHistory 
        WHERE 
            PostId = p.Id AND PostHistoryTypeId IN (4, 5)
    )
WHERE 
    u.Reputation > 1000 
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC
FETCH FIRST 20 ROWS ONLY;