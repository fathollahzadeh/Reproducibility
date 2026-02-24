WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
RecentEdits AS (
    SELECT 
        pe.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory pe
    WHERE 
        pe.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND pe.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        pe.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(re.EditCount, 0) AS RecentEditsCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    RecentEdits re ON rp.Id = re.PostId
WHERE 
    rp.OwnerPostRank = 1
    AND (COALESCE(pvs.TotalVotes, 0) > 10 OR re.EditCount > 2)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 10;