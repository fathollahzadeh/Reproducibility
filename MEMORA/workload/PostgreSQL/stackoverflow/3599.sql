
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ub.BadgeCount,
        ps.UserRank
    FROM 
        PostStats ps
    LEFT JOIN 
        UserBadges ub ON ps.OwnerUserId = ub.UserId
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CommentCount,
    cs.UpVotes,
    cs.DownVotes,
    cs.BadgeCount,
    CASE 
        WHEN cs.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus,
    pht.Name AS PostHistoryType
FROM 
    CombinedStats cs
LEFT JOIN 
    PostHistory ph ON cs.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    cs.UserRank <= 5
ORDER BY 
    cs.UpVotes DESC, 
    cs.CommentCount DESC;
