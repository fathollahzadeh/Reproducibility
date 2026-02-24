
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ABS(vote_count.UpVotes - vote_count.DownVotes), 0) AS VoteBalance,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS CreationRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes v
        INNER JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId
    ) vote_count ON p.Id = vote_count.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.CreationDate DESC) AS RecentRank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= DATE '2024-10-01' - INTERVAL '6 months'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Edit Body' THEN ph.CreationDate END) AS FirstEdit,
        COUNT(CASE WHEN pht.Name = 'Post Closed' THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN pht.Name = 'Post Reopened' THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.VoteBalance,
    ru.DisplayName AS RecentUser,
    ru.Reputation AS UserReputation,
    phd.FirstEdit,
    phd.CloseCount,
    phd.ReopenCount
FROM 
    RankedPosts p
LEFT JOIN 
    RecentUsers ru ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = p.PostId
WHERE 
    p.Rank <= 5 AND 
    (phd.CloseCount > 0 OR phd.ReopenCount > 0)
ORDER BY 
    COALESCE(p.Rank, 0), 
    p.Score DESC, 
    phd.FirstEdit DESC
LIMIT 100;
