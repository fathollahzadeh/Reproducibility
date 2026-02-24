WITH StringProcessing AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
),
TagAnalysis AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        StringProcessing
    GROUP BY 
        Tag
),
RecentComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    WHERE 
        CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month' 
    GROUP BY 
        PostId
),
Engagement AS (
    SELECT 
        sp.PostId,
        sp.Title,
        sp.Body,
        sp.Tags,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        ta.UsageCount AS TagUsageCount
    FROM 
        StringProcessing sp
    LEFT JOIN 
        RecentComments rc ON sp.PostId = rc.PostId
    LEFT JOIN 
        TagAnalysis ta ON ta.Tag = ANY(string_to_array(sp.Tags, '><'))
),
Ranking AS (
    SELECT 
        *,
        (CommentCount * 0.6 + TagUsageCount * 0.4) AS EngagementScore
    FROM 
        Engagement
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CommentCount,
    TagUsageCount,
    EngagementScore
FROM 
    Ranking
ORDER BY 
    EngagementScore DESC
LIMIT 10;