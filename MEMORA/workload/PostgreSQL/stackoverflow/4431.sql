
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
PostVoteDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        rp.UpVotes,
        rp.DownVotes,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS Rank
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND
        ph.Comment IS NOT NULL
    GROUP BY 
        ph.PostId
),
FinalDetails AS (
    SELECT 
        pvd.PostId,
        pvd.Title,
        pvd.Score,
        pvd.ViewCount,
        pvd.CreationDate,
        pvd.OwnerDisplayName,
        pvd.UpVotes,
        pvd.DownVotes,
        COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
        COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM 
        PostVoteDetails pvd
    LEFT JOIN 
        ClosedPosts cp ON pvd.PostId = cp.PostId
)
SELECT 
    *,
    (UpVotes - DownVotes) AS NetVotes,
    (Score + (ViewCount / 100.0)) AS WeightedScore
FROM 
    FinalDetails
WHERE 
    (UpVotes - DownVotes) >= 10
ORDER BY 
    WeightedScore DESC, CreationDate DESC
LIMIT 50;
