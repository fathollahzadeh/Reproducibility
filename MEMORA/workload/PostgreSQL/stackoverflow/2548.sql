WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
TotalVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(tv.UpVotes, 0) AS UpVotes,
        COALESCE(tv.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TotalVotes tv ON rp.Id = tv.PostId
    WHERE 
        rp.rn = 1
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(ps.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.Id
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)
SELECT 
    pu.DisplayName AS TopUser,
    COUNT(ps.Id) AS PostCount,
    AVG(ps.Score) AS AverageScore,
    SUM(ps.ViewCount) AS TotalViews,
    SUM(ps.UpVotes) AS TotalUpVotes,
    SUM(ps.DownVotes) AS TotalDownVotes
FROM 
    TopUsers pu
JOIN 
    PostStats ps ON ps.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = pu.Id)
GROUP BY 
    pu.DisplayName
ORDER BY 
    AverageScore DESC;
