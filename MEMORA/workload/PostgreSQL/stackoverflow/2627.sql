
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        UpVotes, 
        DownVotes, 
        PostsCount, 
        CommentsCount,
        Rank
    FROM 
        UserStats
    WHERE 
        Rank <= 10
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.PostsCount,
    tu.CommentsCount,
    CASE 
        WHEN tu.UpVotes > tu.DownVotes THEN 'Positive Contributor'
        WHEN tu.DownVotes > tu.UpVotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorType,
    (SELECT 
         COUNT(*) 
     FROM 
         Badges b 
     WHERE 
         b.UserId = tu.UserId) AS BadgeCount,
    (SELECT 
         STRING_AGG(t.TagName, ', ') 
     FROM 
         Posts p
         JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
     WHERE 
         p.OwnerUserId = tu.UserId) AS TagNames
FROM 
    TopUsers tu
ORDER BY 
    tu.Reputation DESC;
