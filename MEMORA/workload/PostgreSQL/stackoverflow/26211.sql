
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')  
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS Tag,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        UNNEST(string_to_array(Tags, '>')) -- Group by the Tag from the UNNEST function
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Tags,
    rp.Author,
    rp.Score,
    ts.TotalPosts,
    ts.UpvotedPosts,
    ts.DownvotedPosts,
    phs.CloseVotes,
    phs.ReopenVotes,
    phs.LastEdit
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.Tag = ANY(string_to_array(rp.Tags, '>'))
JOIN 
    PostHistoryStats phs ON phs.PostId = rp.PostId
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
