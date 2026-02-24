WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        AnswerCount,
        OwnerDisplayName,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    ORDER BY 
        VoteCount DESC, ViewCount DESC
    LIMIT 10
),
TagInfo AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.AnswerCount,
    tp.VoteCount,
    ti.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    TagInfo ti ON tp.PostId = ti.PostId
ORDER BY 
    tp.VoteCount DESC;