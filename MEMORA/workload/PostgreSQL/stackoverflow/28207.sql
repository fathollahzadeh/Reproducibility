
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ARRAY_AGG(DISTINCT t.TagName), ARRAY[]::text[]) ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag(TagName) ON true
    LEFT JOIN 
        Tags t ON tag.TagName = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        VoteCount,
        CommentCount,
        TagsArray
    FROM 
        RankedPosts
    WHERE 
        rn = 1 
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.VoteCount,
    FP.CommentCount,
    FP.TagsArray,
    PH.UserDisplayName AS LastEditor,
    PH.CreationDate AS LastEditedDate,
    PH.Comment AS EditComment,
    PH.Text AS NewValue
FROM 
    FilteredPosts FP
LEFT JOIN 
    PostHistory PH ON FP.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) 
WHERE 
    FP.VoteCount > 10 
ORDER BY 
    FP.VoteCount DESC,
    FP.CreationDate ASC;
