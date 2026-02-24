
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        UpVotes, 
        DownVotes, 
        BadgeCount, 
        LastActive,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount,
    t.LastActive,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top Contributor'
        WHEN t.Rank <= 50 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers t
WHERE 
    t.Rank <= 100 
ORDER BY 
    t.Rank;
