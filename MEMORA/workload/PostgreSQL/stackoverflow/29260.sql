WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON true
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 100  
),
PostAnalyses AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.UpVoteCount,
        pp.DownVoteCount,
        pp.CommentCount,
        COALESCE((SELECT COUNT(*) 
                  FROM PostHistory ph 
                  WHERE ph.PostId = pp.PostId 
                    AND ph.PostHistoryTypeId IN (10, 11)), 0) AS CloseReopenCount,
        COALESCE((SELECT COUNT(*) 
                  FROM PostLinks pl 
                  WHERE pl.PostId = pp.PostId 
                    AND pl.LinkTypeId = 3), 0) AS DuplicateCount
    FROM 
        PopularPosts pp
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.CommentCount,
    pa.CloseReopenCount,
    pa.DuplicateCount,
    (0.2 * pa.UpVoteCount + 0.1 * pa.CommentCount - 0.1 * pa.DownVoteCount + 0.3 * pa.CloseReopenCount - 0.5 * pa.DuplicateCount) AS EngagementScore
FROM 
    PostAnalyses pa
ORDER BY 
    EngagementScore DESC
LIMIT 50;