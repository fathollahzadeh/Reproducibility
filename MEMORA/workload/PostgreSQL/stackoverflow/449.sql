WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount,
        ub.BadgeCount,
        pvc.UpVotes,
        pvc.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rn = 1
)
SELECT 
    fp.PostId, 
    fp.Title, 
    fp.CreationDate, 
    fp.Score, 
    COALESCE(fp.ViewCount, 0) AS ViewCount, 
    COALESCE(fp.BadgeCount, 0) AS BadgeCount,
    COALESCE(fp.UpVotes, 0) AS UpVotes,
    COALESCE(fp.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN bp.closedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts bp ON fp.PostId = bp.Id
WHERE 
    fp.ViewCount IS NOT NULL
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 100;