
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '> <')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, p.CreationDate, p.ViewCount, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS ClosureCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v  
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    COALESCE(c.ClosureCount, 0) AS ClosureCount,
    c.LastClosedDate,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN rp.Score IS NULL OR rp.Score < 0 THEN 'Unscored'
        ELSE 'Scored'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts c ON rp.Id = c.PostId
LEFT JOIN 
    PostVoteSummary vs ON rp.Id = vs.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.CreationDate DESC;
