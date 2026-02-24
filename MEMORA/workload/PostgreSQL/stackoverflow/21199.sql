WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE -1 END) AS VoteScore
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
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    CONCAT(u.DisplayName, ' (ID: ', u.Id, ')') AS UserDisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(uv.VoteScore, 0) AS NetVoteScore,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN rp.Score > 0 AND rp.ViewCount > 100 THEN 'Popular'
        ELSE 'Regular'
    END AS Category,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score Available'
        ELSE CAST(rp.Score AS varchar)
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1 
    AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) > 5
ORDER BY 
    NetVoteScore DESC, rp.CreationDate DESC
LIMIT 10;