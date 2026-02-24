WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.Score, p.ViewCount
),
PostHistoryWithTypes AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    phwt.LastCloseDate,
    phwt.LastReopenDate,
    uvs.UpVoteCount,
    uvs.DownVoteCount,
    CASE 
        WHEN phwt.LastCloseDate IS NOT NULL AND phwt.LastReopenDate IS NULL THEN 'Closed' 
        WHEN phwt.LastReopenDate IS NOT NULL THEN 'Reopened' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryWithTypes phwt ON rp.Id = phwt.PostId
LEFT JOIN 
    UserVoteStats uvs ON rp.Id = uvs.PostId
WHERE 
    rp.Score > 10 
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC;