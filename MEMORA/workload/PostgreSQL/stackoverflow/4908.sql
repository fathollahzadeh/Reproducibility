WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(bk.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bk.MaxBadgeClass, 0) AS UserMaxBadgeClass,
    ARRAY_AGG(cpi.Comment) AS CloseReasonComments
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    UserBadges bk ON rp.OwnerUserId = bk.UserId
LEFT JOIN 
    ClosedPostInfo cpi ON rp.PostId = cpi.PostId
WHERE 
    rp.rn = 1
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, vs.UpVotes, vs.DownVotes, bk.BadgeCount, bk.MaxBadgeClass
ORDER BY 
    rp.Score DESC
LIMIT 100;