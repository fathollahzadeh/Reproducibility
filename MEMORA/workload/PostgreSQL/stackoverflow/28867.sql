WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
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
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag
    FROM 
        FilteredPosts
),
TagAggregate AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TagStats
    GROUP BY 
        Tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    STRING_AGG(DISTINCT ta.Tag, ', ') AS Tags,
    COUNT(ta.Tag) AS UniqueTagCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagAggregate ta ON ta.Tag = ANY(string_to_array(fp.Tags, ','))
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Author, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC,
    fp.CommentCount DESC,
    fp.CreationDate DESC;