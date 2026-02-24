
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        RANK() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1  
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        FilteredPosts
    GROUP BY 
        unnest(string_to_array(Tags, ','))
),
TopTags AS (
    SELECT 
        TagName,
        TagFrequency,
        RANK() OVER (ORDER BY TagFrequency DESC) AS FrequencyRank
    FROM 
        TagCounts
)
SELECT 
    f.OwnerDisplayName,
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    tt.TagName,
    tt.TagFrequency
FROM 
    FilteredPosts f
JOIN 
    TopTags tt ON f.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    tt.FrequencyRank <= 5  
ORDER BY 
    f.CreationDate DESC, 
    tt.TagFrequency DESC;
