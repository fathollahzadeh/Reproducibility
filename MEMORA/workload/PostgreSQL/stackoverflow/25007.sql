WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        COUNT(r.PostId) AS RecentPostCount,
        SUM(c.CommentCount) AS TotalComments,
        SUM(r.VoteCount) AS TotalVotes
    FROM 
        Users u
    JOIN 
        RecentPosts r ON u.Id = r.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON r.PostId = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.RecentPostCount,
    au.TotalComments,
    au.TotalVotes,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    ActiveUsers au
LEFT JOIN 
    UserBadges ub ON au.UserId = ub.UserId
ORDER BY 
    au.Reputation DESC, 
    au.TotalVotes DESC
LIMIT 10;