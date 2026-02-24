
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        MAX(p.CreationDate) AS LatestActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        AvgReputation DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.LatestActivityDate,
        tu.DisplayName AS TopUser
    FROM 
        PostStatistics ps
    JOIN 
        TopUsers tu ON ps.UpVotes > 5 
)
SELECT 
    pd.Title,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.LatestActivityDate,
    pd.TopUser
FROM 
    PostDetails pd
WHERE 
    pd.LatestActivityDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' AND TIMESTAMP '2024-10-01 12:34:56'
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC;
