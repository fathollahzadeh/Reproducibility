WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        RankByComments <= 5
)
SELECT 
    fp.*,
    COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), '{}') AS RelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Tags t ON t.TagName = ANY(string_to_array(fp.Tags, '><')) 
GROUP BY 
    fp.PostId, fp.Title, fp.Tags, fp.OwnerDisplayName, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount
ORDER BY 
    fp.CommentCount DESC, fp.UpVoteCount DESC;