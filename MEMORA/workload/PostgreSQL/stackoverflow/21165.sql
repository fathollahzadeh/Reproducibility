WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
), 
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.UpVotes,
        r.DownVotes,
        r.CommentCount,
        r.CloseCount
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5 AND (r.UpVotes - r.DownVotes) > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.UserRank,
    tp.Title,
    tp.UpVotes,
    tp.CommentCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN tp.CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1
    )
ORDER BY 
    u.Reputation DESC, tp.UpVotes DESC;
