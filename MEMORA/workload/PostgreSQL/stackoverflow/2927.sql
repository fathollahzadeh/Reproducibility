
WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT ps.PostId) AS ActivePosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RecentPostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        ps.rn <= 5
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        AVG(u.Reputation) > 1000
),
UserBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.ActivePosts,
    COALESCE(ub.BadgeNames, ARRAY[]::text[]) AS UserBadges,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.ActivePosts > 3
ORDER BY 
    tu.Reputation DESC;
