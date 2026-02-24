
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.LastActivityDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
ComputedTags AS (
    SELECT 
        PostId,
        STRING_AGG(tag, ', ') AS FormattedTags
    FROM 
        (SELECT 
            PostId,
            unnest(string_to_array(Tags, '<>')) AS tag
        FROM 
            FilteredPosts) AS TagList
    GROUP BY 
        PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    ct.FormattedTags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount
FROM 
    FilteredPosts fp
JOIN 
    ComputedTags ct ON fp.PostId = ct.PostId
ORDER BY 
    fp.LastActivityDate DESC;
