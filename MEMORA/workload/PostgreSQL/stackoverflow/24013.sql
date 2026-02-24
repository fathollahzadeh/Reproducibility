
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS RankScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes,
        TotalDownVotes,
        PostCount,
        RankScore
    FROM 
        UserActivity
    WHERE 
        PostCount > 5
), RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        v.UserId
), UserVotePerformance AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(ru.VoteCount, 0) AS RecentVoteCount,
        u.TotalUpVotes - u.TotalDownVotes AS NetVotes,
        u.RankScore
    FROM 
        TopUsers u
    LEFT JOIN 
        RecentVotes ru ON ru.UserId = u.UserId
)

SELECT 
    u.DisplayName,
    u.RecentVoteCount,
    u.NetVotes,
    RANK() OVER (ORDER BY u.NetVotes DESC, u.RecentVoteCount DESC) AS VoteRanking,
    CASE 
        WHEN u.NetVotes > 0 THEN 'Positive Contributor'
        WHEN u.NetVotes < 0 THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributionType
FROM 
    UserVotePerformance u
WHERE 
    u.NetVotes IS NOT NULL
ORDER BY 
    u.NetVotes DESC, u.RecentVoteCount DESC
LIMIT 10;
