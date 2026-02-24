
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.ClosedDate, '1900-01-01') AS ClosedDate,
        LENGTH(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags))) - LENGTH(REPLACE(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags)), '><', '')) + 1 AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostEdits AS (
    SELECT 
        postId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        postId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    COALESCE(pe.EditCount, 0) AS EditCount,
    pe.LastEditDate,
    rp.TagCount,
    CASE 
        WHEN rp.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PostEdits pe ON rp.PostId = pe.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.PostId, rp.Score DESC;
