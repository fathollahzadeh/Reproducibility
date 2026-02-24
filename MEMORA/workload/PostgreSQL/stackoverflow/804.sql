WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
PostVoteCounts AS (
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
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    COALESCE(pc.UpVotes, 0) AS UpVoteCount,
    COALESCE(pc.DownVotes, 0) AS DownVoteCount,
    CASE 
        WHEN pd.ClosedDate IS NOT NULL AND (pd.ReopenedDate IS NULL OR pd.ClosedDate > pd.ReopenedDate) 
        THEN 'Closed' 
        ELSE 'Open' 
    END AS Status,
    p.Score,
    p.CreationDate,
    p.Tags
FROM 
    RankedPosts p
LEFT JOIN 
    PostVoteCounts pc ON p.Id = pc.PostId
LEFT JOIN 
    PostHistoryDetails pd ON p.Id = pd.PostId
WHERE 
    p.rn = 1
    AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    p.Score DESC, p.CreationDate DESC;