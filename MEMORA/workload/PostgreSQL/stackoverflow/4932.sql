
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) AS AvgPostAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            v.UserId,
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            v.UserId
    ) AS vs ON u.Id = vs.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalVotes,
        AvgPostAgeInSeconds,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    t.DisplayName,
    t.PostCount,
    t.TotalVotes,
    t.AvgPostAgeInSeconds,
    CASE 
        WHEN t.TotalVotes = 0 THEN 'No Votes'
        WHEN t.TotalVotes < 10 THEN 'Low Engagement'
        ELSE 'Active User'
    END AS EngagementLevel
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC;
