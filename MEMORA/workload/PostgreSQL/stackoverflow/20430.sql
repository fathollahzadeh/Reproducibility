WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
UserVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.UserId
),
HighestVoted AS (
    SELECT 
        PostId, 
        SUM(UpVotes) - SUM(DownVotes) AS VoteDifferential
    FROM 
        UserVotes
    GROUP BY 
        PostId
),
PostHistoryUpdates AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(hv.VoteDifferential, 0) AS TotalVotes,
    COALESCE(ph.LastCloseDate, ph.LastReopenDate, NULL) AS LastUpdate,
    CASE 
        WHEN rp.RankScore = 1 THEN 'Top Post'
        ELSE 'Regular Post' 
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    HighestVoted hv ON rp.PostId = hv.PostId
LEFT JOIN 
    PostHistoryUpdates ph ON rp.PostId = ph.PostId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 50;