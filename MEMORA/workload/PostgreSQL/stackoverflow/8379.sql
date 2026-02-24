WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, b.Class
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.Reputation,
        ub.BadgeCount,
        COUNT(ap.PostId) AS ActivePostCount,
        SUM(ap.CommentCount) AS TotalComments,
        SUM(ap.UpVoteCount) AS TotalUpVotes,
        SUM(ap.DownVoteCount) AS TotalDownVotes
    FROM 
        UserBadges ub
    LEFT JOIN 
        ActivePosts ap ON ub.UserId = ap.OwnerUserId
    GROUP BY 
        ub.UserId, ub.Reputation, ub.BadgeCount
)
SELECT 
    tu.UserId,
    tu.Reputation,
    tu.BadgeCount,
    tu.ActivePostCount,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    TopUsers tu
WHERE 
    tu.ActivePostCount > 0
ORDER BY 
    tu.Reputation DESC, tu.ActivePostCount DESC
LIMIT 10;