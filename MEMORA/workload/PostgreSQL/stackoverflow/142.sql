
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        RankScore,
        CommentCount,
        UpVotes
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
)
SELECT 
    tp.Title AS PostTitle,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    COALESCE(tp.CommentCount, 0) AS CommentCount,
    CONCAT('Score: ', tp.Score, ' | UpVotes: ', tp.UpVotes) AS VoteDetails,
    CASE 
        WHEN tp.Score IS NULL THEN 'No Score' 
        ELSE 'Score exists' 
    END AS ScoreStatus,
    CASE 
        WHEN tp.CreationDate < CURRENT_DATE - INTERVAL '6 months' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    b.Class = 1 OR b.Class = 2
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
