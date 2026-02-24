
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagsArray AS (
    SELECT 
        p.PostId, 
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts p
    CROSS JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag
    JOIN 
        Tags t ON t.TagName = TRIM(tag) 
    GROUP BY 
        p.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount,
        rp.AnswerCount,
        ta.TagsList,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC, rp.CreationDate ASC) AS PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId IN (2, 1) 
    JOIN 
        TagsArray ta ON ta.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Owner, rp.CommentCount, rp.AnswerCount, ta.TagsList
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.TagsList,
    tp.CreationDate,
    tp.Owner,
    tp.CommentCount,
    tp.AnswerCount,
    tp.PostRank
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.PostRank, tp.CreationDate DESC;
