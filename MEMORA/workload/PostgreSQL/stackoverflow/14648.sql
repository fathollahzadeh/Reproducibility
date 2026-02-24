WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        u.CreationDate,
        COALESCE(uv.TotalVotes, 0) AS TotalVotes,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        UserVotes uv ON u.Id = uv.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.TotalVotes,
    au.UpVotes,
    au.DownVotes,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    ps.ClosedPosts
FROM 
    ActiveUsers au
LEFT JOIN 
    PostStatistics ps ON au.Id = ps.OwnerUserId
ORDER BY 
    au.Reputation DESC, au.TotalVotes DESC;