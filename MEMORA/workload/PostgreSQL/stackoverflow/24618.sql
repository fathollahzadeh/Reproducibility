
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
), PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top'
            WHEN rp.Rank <= 3 THEN 'Top 3'
            ELSE 'Other'
        END AS RankCategory,
        COALESCE(ph.Comment, 'No close reason') AS LastCloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 
)
SELECT 
    ps.Author,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.RankCategory,
    ps.LastCloseReason,
    CASE 
        WHEN ps.Score = 0 THEN 'No Score Yet'
        WHEN ps.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreDescription,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
FROM 
    PostStats ps
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId
WHERE 
    ps.Score > 0 OR ps.LastCloseReason IS NOT NULL
GROUP BY 
    ps.Author, ps.Title, ps.Score, ps.ViewCount, ps.RankCategory, ps.LastCloseReason
ORDER BY 
    ps.Score DESC, UpVotes DESC
LIMIT 100
OFFSET 0;
