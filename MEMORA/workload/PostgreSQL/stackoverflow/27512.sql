
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.ViewCount, p.CreationDate
),
TopTags AS (
    SELECT 
        Tags AS TopTag,
        COUNT(*) AS TagUsageCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  
    GROUP BY 
        Tags
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10  
),
StringProcessing AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.CommentCount,
        r.UpVoteCount,
        r.DownVoteCount,
        ARRAY_LENGTH(string_to_array(r.Tags, ','), 1) AS TagCount,
        COALESCE(TOP.TopTag, 'No Tag') AS PopularTag
    FROM 
        RankedPosts r
    LEFT JOIN 
        TopTags TOP ON r.Tags LIKE '%' || TOP.TopTag || '%'
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    TagCount,
    PopularTag,
    CASE 
        WHEN UpVoteCount > DownVoteCount THEN 'Positive Engagement'
        WHEN DownVoteCount > UpVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    StringProcessing
ORDER BY 
    ViewCount DESC, UpVoteCount DESC;
