
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
), CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.BadgeCount, 0) AS BadgeCount,
        COALESCE(us.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(us.TotalDownVotes, 0) AS TotalDownVotes,
        COUNT(rp.PostId) AS RecentPostsCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        UserVoteStats us ON u.Id = us.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn <= 5
    GROUP BY 
        u.Id, u.DisplayName, rb.BadgeCount, us.TotalUpVotes, us.TotalDownVotes
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.BadgeCount,
    cs.TotalUpVotes,
    cs.TotalDownVotes,
    cs.RecentPostsCount,
    (cs.TotalUpVotes - cs.TotalDownVotes) AS VoteNet,
    CASE 
        WHEN cs.BadgeCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    CombinedStats cs
WHERE 
    cs.RecentPostsCount > 0
ORDER BY 
    VoteNet DESC, cs.RecentPostsCount DESC;
