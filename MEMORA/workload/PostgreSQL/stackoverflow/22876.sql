WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER(PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER(PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.Score >= 0
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

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS Closer,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    u.DisplayName, 
    up.PostId, 
    up.Title, 
    up.CreationDate AS PostCreationDate, 
    up.Score AS PostScore, 
    COALESCE(up.UpVotes, 0) - COALESCE(up.DownVotes, 0) AS VoteNet,
    ub.BadgeCount,
    pb.ClosedPostCount,
    pb.ClosedBy
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN (
    SELECT 
        cp.PostId,
        COUNT(cp.PostId) AS ClosedPostCount,
        STRING_AGG(DISTINCT cp.Closer, ', ') AS ClosedBy
    FROM 
        ClosedPosts cp
    GROUP BY 
        cp.PostId
) pb ON up.PostId = pb.PostId
WHERE 
    up.Rank = 1
ORDER BY 
    VoteNet DESC, 
    up.Score DESC;