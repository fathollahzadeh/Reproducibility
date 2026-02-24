
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(z.Reputation, 0) AS UserReputation,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users z ON p.OwnerUserId = z.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, z.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.UserReputation,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.PostTypeId IN (1, 2) 
        AND rp.UserReputation > 100
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12) THEN 1 END) AS DeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    CONCAT('Owner ID: ', fp.OwnerUserId, ' | Reputation: ', fp.UserReputation) AS UserDetails,
    fp.UpVotes - fp.DownVotes AS VoteBalance,
    COALESCE(pHS.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(pHS.DeletionCount, 0) AS DeletionCount,
    CASE 
        WHEN COALESCE(pHS.DeletionCount, 0) > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryStats pHS ON fp.Id = pHS.PostId
ORDER BY 
    fp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
