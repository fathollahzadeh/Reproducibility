
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
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
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        rp.VoteCount > 10 AND 
        rp.CommentCount > 5
),
FinalOutput AS (
    SELECT 
        fp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        LATERAL (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(fp.Tags, 2, LENGTH(fp.Tags) - 2), '><')) AS tag) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
    LEFT JOIN 
        PostLinks pl ON fp.PostId = pl.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.OwnerDisplayName, fp.CommentCount, fp.VoteCount
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CommentCount,
    f.VoteCount,
    f.RelatedTags,
    f.RelatedPostCount,
    f.CreationDate
FROM 
    FinalOutput f
ORDER BY 
    f.VoteCount DESC, f.CommentCount DESC;
