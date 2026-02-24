
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankView
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        Score, 
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5 OR RankView <= 5
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Id IN (SELECT PostId FROM TopRankedPosts)
    GROUP BY 
        p.Id
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.OwnerDisplayName,
    tr.CreationDate,
    tr.Score,
    tr.ViewCount,
    pvd.UpVotes,
    pvd.DownVotes,
    ROUND((pvd.UpVotes::DECIMAL / NULLIF((pvd.UpVotes + pvd.DownVotes), 0)) * 100, 2) AS UpVotePercentage
FROM 
    TopRankedPosts tr
JOIN 
    PostVoteDetails pvd ON tr.PostId = pvd.PostId
ORDER BY 
    tr.Score DESC, tr.ViewCount DESC
LIMIT 50;
