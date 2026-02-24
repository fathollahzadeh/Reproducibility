
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.Score > 20 THEN 'High Score'
            WHEN rp.Score >= 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS Rank
    FROM 
        RecentPosts rp
), BestPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes DESC, ps.ViewCount DESC) AS BestRank
    FROM 
        PostStatistics ps
)
SELECT 
    bp.PostId,
    bp.Title,
    bp.CreationDate,
    bp.Score,
    bp.ViewCount,
    bp.UpVotes,
    bp.DownVotes,
    bp.CommentCount,
    bp.AnswerCount,
    bp.ScoreCategory
FROM 
    BestPosts bp
WHERE 
    bp.BestRank <= 10
UNION ALL
SELECT 
    -bp.PostId AS PostId,  
    CONCAT('Unpopular Post: ', bp.Title) AS Title,
    bp.CreationDate,
    0 AS Score,
    0 AS ViewCount,
    0 AS UpVotes,
    0 AS DownVotes,
    0 AS CommentCount,
    0 AS AnswerCount,
    'Unpopular' AS ScoreCategory
FROM 
    PostStatistics bp
WHERE 
    bp.Score <= 0
    AND NOT EXISTS (SELECT 1 FROM BestPosts b WHERE b.PostId = bp.PostId)
ORDER BY 
    CreationDate DESC
LIMIT 5;
