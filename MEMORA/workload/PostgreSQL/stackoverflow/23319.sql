
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 0 
            ELSE u.Reputation 
        END AS SafeReputation
    FROM 
        Users u
),
VoteDetail AS (
    SELECT 
        v.PostId,
        SUM(CASE 
            WHEN vt.Name = 'UpMod' THEN 1 
            WHEN vt.Name = 'DownMod' THEN -1 
            ELSE 0 
        END) AS NetVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(ud.SafeReputation, 0) AS UserReputation,
    COALESCE(vd.NetVotes, 0) AS NetVotes,
    cr.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserReputation ud ON u.Id = ud.UserId
LEFT JOIN 
    VoteDetail vd ON rp.PostId = vd.PostId
LEFT JOIN 
    ClosedPostReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.Rank <= 10 
    AND (rp.ViewCount > 100 OR cr.CloseReasons IS NOT NULL)
ORDER BY 
    rp.ViewCount DESC,
    rp.CreationDate DESC;
