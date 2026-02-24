
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.CreationDate, p.LastActivityDate, p.Tags
), 
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        CreationDate,
        LastActivityDate,
        Tags,
        TagRank,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 3  
)
SELECT 
    f.Title,
    f.ViewCount,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.CreationDate,
    f.LastActivityDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    FilteredPosts f
JOIN 
    UNNEST(STRING_TO_ARRAY(f.Tags, ',')) AS tag_ids ON TRUE
JOIN 
    Tags t ON t.TagName = TRIM(BOTH '"' FROM tag_ids)
GROUP BY 
    f.Title, f.ViewCount, f.CommentCount, f.UpVotes, f.DownVotes, f.CreationDate, f.LastActivityDate
ORDER BY 
    f.ViewCount DESC, f.CreationDate DESC
LIMIT 
    10;
