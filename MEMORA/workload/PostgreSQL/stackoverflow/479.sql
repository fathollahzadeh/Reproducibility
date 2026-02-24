WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        pv.UpVotes,
        pv.DownVotes,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.Id = pv.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    Title,
    Score,
    ViewCount,
    UpVotes,
    DownVotes,
    CloseCount,
    CASE 
        WHEN CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN UpVotes > DownVotes THEN 'Positive' 
        ELSE 'Negative' 
    END AS VoteStatus
FROM 
    FilteredPosts
ORDER BY 
    Score DESC, Title ASC;