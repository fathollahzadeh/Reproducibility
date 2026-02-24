WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
UserVotingStats AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN pht.Name IN ('Post Closed', 'Post Deleted') THEN 1 END) AS CloseDeleteCount,
        COUNT(CASE WHEN pht.Name = 'Post Reopened' THEN 1 END) AS ReopenedCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    COALESCE(uvs.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(uvs.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(phs.CloseDeleteCount, 0) AS CloseDeleteCount,
    COALESCE(phs.ReopenedCount, 0) AS ReopenedCount,
    DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotingStats uvs ON rp.OwnerUserId = uvs.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;