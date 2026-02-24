WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        ps.TotalPosts,
        ps.PositivePosts,
        ps.NegativePosts,
        ps.TotalComments,
        ROW_NUMBER() OVER (ORDER BY uv.TotalVotes DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        UserVotes uv ON u.Id = uv.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalVotes,
    UpVotes,
    DownVotes,
    TotalPosts,
    PositivePosts,
    NegativePosts,
    TotalComments,
    Rank
FROM 
    UserPostStats
WHERE 
    TotalPosts > 0
ORDER BY 
    Rank;
