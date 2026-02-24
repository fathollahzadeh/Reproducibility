WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(COUNT(v.Id), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
RecentResolutions AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId,
        ph.CreationDate AS ResolutionDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ResolutionRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 19, 20)  
),
PostStatistics AS (
    SELECT 
        rp.*,
        rr.ResolutionDate,
        CASE 
            WHEN rr.ResolutionRank = 1 AND rr.PostHistoryTypeId IN (10) THEN 'Closed'
            WHEN rr.ResolutionRank = 1 AND rr.PostHistoryTypeId IN (11) THEN 'Reopened'
            ELSE 'Active' 
        END AS Status
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentResolutions rr ON rp.PostId = rr.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Status,
    CASE 
        WHEN ps.ViewCount > 100 AND ps.Score < 0 THEN 'Needs Attention'
        WHEN ps.ViewCount < 10 THEN 'Newbie Question'
        WHEN ps.ViewCount >= 10 AND ps.UpVotes > ps.DownVotes THEN 'Popular'
        ELSE 'Mixed'
    END AS Category,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostStatistics ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.ViewCount, ps.Score, ps.VoteCount, ps.UpVotes, ps.DownVotes, ps.Status
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;