
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(bp.BadgeNames, 'No badges') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        UserBadges bp ON bp.UserId = u.Id
    WHERE 
        u.Reputation > 1000 AND 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    cp.CloseDate,
    cp.CloseReason,
    au.DisplayName AS ActiveUser,
    au.Badges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
LEFT JOIN 
    ActiveUsers au ON au.Id = rp.PostId 
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC, rp.CommentCount DESC;
