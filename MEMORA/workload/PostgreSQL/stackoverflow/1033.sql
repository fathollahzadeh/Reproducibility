WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
PostStats AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.HistoryDate IS NOT NULL THEN 1 END), 0) AS HistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVoteCounts uv ON rp.Id = uv.PostId
    LEFT JOIN 
        PostHistoryDetails ph ON rp.Id = ph.PostId
    GROUP BY 
        rp.Id, rp.Title, rp.CreationDate, rp.Score, uv.UpVotes, uv.DownVotes
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.HistoryCount,
    CASE 
        WHEN ps.Score > 50 THEN 'High Score'
        WHEN ps.Score BETWEEN 20 AND 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostStats ps
WHERE 
    ps.HistoryCount > 0
ORDER BY 
    ps.Score DESC, ps.CreationDate ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;