
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
        AND p.ViewCount > 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 501 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(h.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes cr ON h.Comment::INTEGER = cr.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '6 months' 
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rc.UpVotesCount,
    rc.DownVotesCount,
    up.ReputationLevel,
    cp.CloseReasonCount,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts rc ON rp.PostId = rc.PostId
LEFT JOIN 
    UserReputation up ON rp.PostId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
    AND (rc.UpVotesCount IS NULL OR rc.UpVotesCount > rc.DownVotesCount)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
