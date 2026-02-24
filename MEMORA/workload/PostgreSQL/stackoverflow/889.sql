
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
RankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS ScoreRank
    FROM 
        PostStats
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, Score, CommentCount, UpVotes, DownVotes, ScoreRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.UpVotes + tp.DownVotes > 0 
        THEN ROUND((tp.UpVotes::decimal / (tp.UpVotes + tp.DownVotes)) * 100, 2)
        ELSE NULL 
    END AS UpvotePercentage
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    b.Id IS NULL
ORDER BY 
    tp.Score DESC;
