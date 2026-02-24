WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
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
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalBounty,
    RPH.UserId AS LastUserToClose,
    RPH.CreationDate AS LastCloseDate,
    ub.BadgeCount AS UserBadgeCount,
    ub.HighestBadgeClass
FROM 
    PostStats ps
LEFT JOIN 
    RecursivePostHistory RPH ON ps.PostId = RPH.PostId AND RPH.rn = 1
LEFT JOIN 
    Users u ON RPH.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    ps.TotalBounty > 0
    OR ps.CommentCount > 5
ORDER BY 
    ps.TotalBounty DESC, ps.CommentCount DESC;