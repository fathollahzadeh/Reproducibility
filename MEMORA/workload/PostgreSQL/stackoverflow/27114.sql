
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 10  
),
PostSummary AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes, 
        rp.DownVotes,
        tt.TagName
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%'
)
SELECT 
    Title,
    OwnerDisplayName,
    CommentCount,
    UpVotes,
    DownVotes,
    STRING_AGG(TagName, ', ') AS Tags
FROM 
    PostSummary
GROUP BY 
    Title, OwnerDisplayName, CommentCount, UpVotes, DownVotes
ORDER BY 
    UpVotes DESC, CommentCount DESC;
