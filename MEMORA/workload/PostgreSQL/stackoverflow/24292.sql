
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        CASE 
            WHEN p.Score > 100 THEN 'High Score'
            WHEN p.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rb.BadgeCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    rp.ScoreCategory,
    CASE 
        WHEN rb.BadgeCount IS NULL OR rb.BadgeCount = 0 THEN 'No Gold Badges'
        ELSE 'Gold Badge Holder'
    END AS BadgeStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC,
    rp.CreationDate DESC;