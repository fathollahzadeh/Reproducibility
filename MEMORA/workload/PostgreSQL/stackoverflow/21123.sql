
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), '<No Content>') AS PostBody,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 
PostVoteStats AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        vt.Name IN ('UpMod', 'DownMod')
    GROUP BY 
        v.PostId
), 
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No Comment' END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    ub.BadgeNames,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Rank,
    rp.Score,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(rc.CloseCount, 0) AS CloseCount,
    rc.CloseReasons,
    CASE 
        WHEN rc.CloseCount > 0 THEN 'Closed'
        ELSE 'Active' 
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN 
    PostVoteStats pvs ON pvs.PostId = rp.PostId
LEFT JOIN 
    CloseReasonCounts rc ON rc.PostId = rp.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
