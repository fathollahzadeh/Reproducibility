
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(p.Score, 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.Score,
    STRING_AGG(DISTINCT UPPER(t.TagName), ', ') AS UniqueTags 
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(tp.Tags, '><')) AS TagName
    ) t ON TRUE
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.AnswerCount, tp.Score
ORDER BY 
    tp.Score DESC, tp.AnswerCount DESC;
