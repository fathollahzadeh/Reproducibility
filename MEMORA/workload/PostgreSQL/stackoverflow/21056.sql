
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.LastActivityDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.*,
        uv.UpVotes,
        uv.DownVotes,
        phc.EditCount,
        phc.CloseOpenCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVotes uv ON rp.PostId = uv.PostId
    LEFT JOIN 
        PostHistoryCounts phc ON rp.PostId = phc.PostId
)
SELECT 
    cd.PostId,
    cd.OwnerUserId,
    cd.Title,
    cd.Score,
    cd.ViewCount,
    cd.LastActivityDate,
    COALESCE(cd.UpVotes, 0) AS TotalUpVotes,
    COALESCE(cd.DownVotes, 0) AS TotalDownVotes,
    cd.EditCount,
    cd.CloseOpenCount,
    CASE 
        WHEN cd.PostRank <= 3 THEN 'Top Performer'
        WHEN cd.EditCount > 5 THEN 'Heavily Edited'
        ELSE 'Standard'
    END AS PostClassification
FROM 
    CombinedData cd
WHERE 
    cd.PostRank <= 10
GROUP BY 
    cd.PostId,
    cd.OwnerUserId,
    cd.Title,
    cd.Score,
    cd.ViewCount,
    cd.LastActivityDate,
    cd.UpVotes,
    cd.DownVotes,
    cd.EditCount,
    cd.CloseOpenCount,
    cd.PostRank
ORDER BY 
    cd.Score DESC,
    cd.ViewCount DESC
