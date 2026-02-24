WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS comment_rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pvd.UpVotes, 0) AS UpVotes,
    COALESCE(pvd.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN hp.UserDisplayName IS NOT NULL THEN 
            CONCAT('Last changed by ', hp.UserDisplayName, ' on ', hp.CreationDate)
        ELSE 
            'No recent history on this post'
    END AS RecentHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes pvd ON rp.PostId = pvd.PostId
LEFT JOIN 
    PostHistoryDetails hp ON rp.PostId = hp.PostId AND hp.comment_rn = 1
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
