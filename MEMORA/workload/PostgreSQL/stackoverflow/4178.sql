WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score END), 0) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    uv.TotalVotes,
    uv.UpVotes,
    uv.DownVotes,
    uv.AvgPostScore,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostCreationDate
FROM 
    Users u
LEFT JOIN 
    UserVoteStats uv ON u.Id = uv.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    u.Reputation > 1000
AND 
    (uv.TotalVotes IS NULL OR uv.TotalVotes > 10)
ORDER BY 
    uv.TotalVotes DESC NULLS LAST, u.DisplayName;