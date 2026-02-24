
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        p.AnswerCount, 
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' AND 
        p.ViewCount > 100
),
RecentActivity AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActivityDate,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS RecentComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    ra.LastActivityDate,
    ra.HistoryCount,
    ra.RecentComments,
    vs.UpVotes,
    vs.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostId, rp.Rank;
