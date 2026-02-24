WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pc.UpVotes,
        pc.DownVotes,
        upc.UserId,
        upc.PostCount
    FROM 
        Posts p
    JOIN 
        PostVoteCounts pc ON p.Id = pc.PostId
    JOIN 
        UserPostCounts upc ON p.OwnerUserId = upc.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.PostCount
FROM 
    PostSummary ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 10;