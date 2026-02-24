WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
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
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS HistoryAction
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT ph.HistoryAction, ', ') AS Actions
    FROM 
        PostHistories ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(pHS.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(pHS.Actions, 'None') AS RecentActions
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistorySummary pHS ON tp.PostId = pHS.PostId
WHERE 
    tp.OverallRank <= 10
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;