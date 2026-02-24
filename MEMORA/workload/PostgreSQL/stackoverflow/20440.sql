
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditDate,
        STRING_AGG(DISTINCT c.Text, '; ') AS CloseComments
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.PostHistoryTypeId = 10
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    cp.CloseDate,
    cp.LastEditDate,
    COALESCE(cp.CloseComments, 'No close comments') AS CloseComments,
    CASE 
        WHEN rp.Score IS NULL OR rp.Score < 0 THEN 'Negative or No Score'
        WHEN rp.Score > 0 THEN 'Positive Score'
        ELSE 'Neutral'
    END AS ScoreStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId 
        AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CreationDate DESC;
