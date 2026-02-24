WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        COALESCE(pl.RelatedPostId, -1) AS RelatedPostId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(us.UpVotes, 0) AS TotalUpVotes,
    COALESCE(us.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phs.HistoryTypes, 'No Changes') AS ChangeTypes,
    COALESCE(phs.HistoryCount, 0) AS ChangeCount,
    CASE 
        WHEN rp.AnswerCount > 5 THEN 'Hot'
        WHEN rp.Score > 100 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteSummary us ON rp.PostId = us.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC NULLS LAST, rp.CreationDate DESC;