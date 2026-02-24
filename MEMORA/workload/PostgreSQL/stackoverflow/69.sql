WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        OwnerDisplayName,
        Rank,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS VoteBalance
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.*, 
    COALESCE(phs.EditCount, 0) AS EditCount,
    (CASE 
         WHEN ps.ViewCount > 1000 THEN 'High'
         WHEN ps.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
         ELSE 'Low'
     END) AS Popularity,
    (CASE 
         WHEN ps.VoteBalance > 0 THEN 'Positive'
         WHEN ps.VoteBalance < 0 THEN 'Negative'
         ELSE 'Neutral'
     END) AS OverallSentiment
FROM 
    PostStats ps
LEFT JOIN 
    PostHistorySummary phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.ViewCount DESC, ps.AnswerCount DESC;
