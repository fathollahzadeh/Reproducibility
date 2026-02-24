
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        array_length(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        p.ViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.CreationDate, p.ViewCount, p.Tags
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, pht.Name
),
PostBenchmarking AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CreationDate,
        rp.TagCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.ViewCount,
        COALESCE(SUM(CASE WHEN p.ChangeCount > 0 THEN 1 END), 0) AS TotalChanges
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistoryData p ON rp.PostId = p.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerName, rp.CreationDate, rp.TagCount, rp.CommentCount, rp.VoteCount, rp.ViewCount
)
SELECT 
    PostId,
    Title,
    OwnerName,
    CreationDate,
    TagCount,
    CommentCount,
    VoteCount,
    ViewCount,
    TotalChanges,
    CASE 
        WHEN ViewCount > 500 THEN 'High Engagement'
        WHEN ViewCount BETWEEN 100 AND 500 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostBenchmarking
ORDER BY 
    ViewCount DESC, TotalChanges DESC
LIMIT 10;
