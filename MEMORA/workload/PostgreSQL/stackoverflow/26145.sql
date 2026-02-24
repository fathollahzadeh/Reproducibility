WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags,
        COALESCE(
            (SELECT COUNT(*) FROM Posts a WHERE a.AcceptedAnswerId = p.Id), 0
        ) AS AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        tag.TagName,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY tag.Count DESC) AS TagRank
    FROM 
        RankedPosts rp
    JOIN 
        Tags tag ON rp.Tags LIKE '%' || tag.TagName || '%'
),
FrequentTaggers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(*) AS PostsTagged
    FROM 
        TaggedPosts tp
    JOIN 
        Users U ON tp.OwnerDisplayName = U.DisplayName
    WHERE 
        tp.TagRank <= 3 
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(*) > 5 
)
SELECT 
    ft.DisplayName AS TaggerName,
    ft.PostsTagged AS TotalTagsUsed,
    ARRAY_AGG(DISTINCT tp.TagName) AS PopularTags,
    COUNT(*) AS TotalPosts
FROM 
    FrequentTaggers ft
JOIN 
    TaggedPosts tp ON tp.OwnerDisplayName = ft.DisplayName
GROUP BY 
    ft.DisplayName, ft.PostsTagged
ORDER BY 
    TotalTagsUsed DESC, TaggerName;