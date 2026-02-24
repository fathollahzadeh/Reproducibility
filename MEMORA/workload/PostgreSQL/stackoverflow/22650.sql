
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE 
            WHEN vt.Name IN ('UpMod', 'AcceptedByOriginator') THEN 1 
            WHEN vt.Name = 'DownMod' THEN -1 
            ELSE 0 
        END) AS NetVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)

SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.Score AS LatestPostScore,
    COALESCE(cr.CloseReasonNames, 'Not Closed') AS PostCloseReasons,
    COALESCE(uv.NetVotes, 0) AS PostNetVotes,
    CASE 
        WHEN up.BadgeCount = 0 THEN 'Novice'
        WHEN up.BadgeCount BETWEEN 1 AND 5 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.UserPostRank = 1
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
WHERE 
    up.Reputation > 50
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC;
