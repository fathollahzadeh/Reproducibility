
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM 
        UserActivity
)

SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    tu.CommentCount, 
    tu.UpVotes, 
    tu.DownVotes,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        WHEN tu.Rank <= 50 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 100
ORDER BY 
    tu.Rank;
