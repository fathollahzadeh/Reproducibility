WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    CASE 
        WHEN fp.Score IS NOT NULL AND fp.CommentCount = 0 THEN 'No Comments Yet'
        WHEN fp.Score IS NULL AND fp.CommentCount > 0 THEN 'Commented but No Score'
        ELSE 'Active with Scores and Comments'
    END AS PostStatus,
    CASE 
        WHEN fp.Score IS NOT NULL THEN fp.Score * 100.0 / NULLIF((SELECT SUM(Score) FROM Posts), 0)
        ELSE NULL
    END AS ScorePercentage,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(unnest(string_to_array(p.Tags, '<>'))) AS TagName
    ) t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.ViewCount, fp.UpVotes, fp.DownVotes, fp.CommentCount
HAVING 
    SUM(fp.UpVotes) > SUM(fp.DownVotes)
ORDER BY 
    fp.Score DESC NULLS LAST;