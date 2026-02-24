
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), '1970-01-01') AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days'
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostScores AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY rp.LastVoteDate DESC) AS LastVoteRank
    FROM 
        RecentPosts rp
),
TopPosts AS (
    SELECT 
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.ScoreRank,
        ps.LastVoteRank
    FROM 
        PostScores ps
    WHERE 
        ps.ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    CASE 
        WHEN tp.LastVoteRank = 1 THEN 'Recently Voted'
        ELSE 'Not Recently Voted'
    END AS VoteStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
