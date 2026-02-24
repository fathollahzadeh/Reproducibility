WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.UpVotes,
        fp.DownVotes,
        (fp.UpVotes - fp.DownVotes) AS NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseCount
    FROM 
        FilteredPosts fp
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.NetVotes,
    pd.CommentCount,
    pd.CloseCount,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostDetails pd
JOIN 
    Users u ON pd.PostId = u.Id
WHERE 
    u.Reputation > 1000 
    AND pd.ViewCount > 50 
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;