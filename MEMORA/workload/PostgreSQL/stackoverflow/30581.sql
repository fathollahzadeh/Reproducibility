WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), RecentlyEditedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS EditorDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
        AND ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
), PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    rec.EditDate,
    rec.EditorDisplayName,
    rec.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.Id = pvc.PostId
LEFT JOIN 
    RecentlyEditedPosts rec ON rp.Id = rec.Id
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;