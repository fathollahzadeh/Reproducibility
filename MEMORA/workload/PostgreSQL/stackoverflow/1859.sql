
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        (rp.Score + COALESCE(v.UpVoteCount, 0) - COALESCE(v.DownVoteCount, 0)) AS AdjustedScore
    FROM 
        RecentPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVoteCount,
            COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AdjustedScore,
    tu.DisplayName AS TopUser
FROM 
    PostScores ps
LEFT JOIN 
    TopUsers tu ON ps.OwnerName = tu.DisplayName
ORDER BY 
    ps.AdjustedScore DESC
LIMIT 5;
