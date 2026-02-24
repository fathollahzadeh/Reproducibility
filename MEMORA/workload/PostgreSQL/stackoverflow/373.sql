
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
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
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cht.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cht ON CAST(ph.Comment AS INTEGER) = cht.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(cph.CloseReasons, 'No Close Reasons') AS CloseReasons,
    COALESCE(cph.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN 
    ClosedPostHistory cph ON rp.Id = cph.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
