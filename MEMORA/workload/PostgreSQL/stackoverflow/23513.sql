WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        p.Tags,
        (CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(ph.Comment AS INT)) 
            ELSE NULL 
        END) AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostWithVotes AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(av.UpVotes, 0) AS UpVotes,
        COALESCE(av.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        AggregatedVotes av ON p.Id = av.PostId
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    php.PostId,
    php.Title,
    php.HistoryDate,
    p.OwnerDisplayName,
    CAST(COALESCE(CAST(php.CloseReason AS VARCHAR), 'Open') AS VARCHAR) AS PostStatus,
    RANK() OVER (ORDER BY php.HistoryDate DESC) AS HistoryRank,
    pv.UpVotes - pv.DownVotes AS ScoreChange,
    ROW_NUMBER() OVER (PARTITION BY php.PostId ORDER BY php.HistoryDate DESC) AS RecentUpdates
FROM 
    PostHistoryData php
JOIN 
    Posts p ON php.PostId = p.Id
LEFT JOIN 
    PostWithVotes pv ON php.PostId = pv.Id
WHERE 
    php.HistoryDate IS NOT NULL
ORDER BY 
    php.HistoryDate DESC, ScoreChange DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;