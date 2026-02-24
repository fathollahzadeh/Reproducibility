WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened' 
            ELSE CAST(ph.CreationDate AS varchar) 
        END, ', ') AS PostHistory,
        COUNT(DISTINCT ph.Id) AS RevisionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(h.PostHistory, 'No history') AS PostHistory,
    COALESCE(h.RevisionCount, 0) AS RevisionCount,
    RANK() OVER (ORDER BY COALESCE(v.VoteCount, 0) DESC) AS VoteRank
FROM 
    RankedPosts p
LEFT JOIN 
    RecentVotes v ON p.PostId = v.PostId
LEFT JOIN 
    PostHistoryDetails h ON p.PostId = h.PostId
WHERE 
    p.rn = 1 
ORDER BY 
    VoteRank, p.CreationDate DESC;