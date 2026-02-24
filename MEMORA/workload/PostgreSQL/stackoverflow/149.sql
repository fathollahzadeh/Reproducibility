
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS EngagementRank
    FROM 
        UserStats
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.UpVotes,
    ru.DownVotes,
    ru.PostCount,
    ru.CommentCount,
    CASE 
        WHEN ru.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN ru.CommentCount > 50 THEN 'Active Commentator'
        ELSE 'Regular User'
    END AS UserType,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = ru.UserId AND p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')) AS RecentPostsCount
FROM 
    RankedUsers ru
WHERE 
    ru.PostCount > 5
ORDER BY 
    EngagementRank ASC, Reputation DESC
LIMIT 20;
