
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        ViewCount > 1000
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    uv.UpVotes,
    uv.DownVotes,
    CASE 
        WHEN ps.AverageScore IS NULL THEN 'No Tags Found'
        ELSE ps.TagName || ' (Average Score: ' || COALESCE(CAST(ps.AverageScore AS TEXT), '0') || ')'
    END AS PopularTag
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostID = uv.PostId
LEFT JOIN 
    TagStatistics ps ON rp.Score > ps.AverageScore
WHERE 
    rp.ScoreRank <= 5 
    AND rp.TotalPosts > 10
ORDER BY 
    rp.Score DESC, 
    uv.UpVotes DESC
LIMIT 100;
