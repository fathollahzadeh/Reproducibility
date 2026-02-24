
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(a.Id) AS AnswerCount,
        MAX(h.CreationDate) AS LastEditedDate,
        RANK() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS Ranking
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.AnswerCount,
        rp.LastEditedDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Ranking = 1 
        AND rp.AnswerCount > 5 
),
QuestionTags AS (
    SELECT 
        f.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        FilteredPosts f
    JOIN 
        UNNEST(STRING_TO_ARRAY(f.Tags, ',')) AS tagArray ON tagArray IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(tagArray)
    GROUP BY 
        f.PostId
)
SELECT 
    ft.PostId,
    ft.Title,
    ft.Body,
    ft.Author,
    ft.AnswerCount,
    ft.LastEditedDate,
    qt.Tags
FROM 
    FilteredPosts ft
JOIN 
    QuestionTags qt ON ft.PostId = qt.PostId
ORDER BY 
    ft.LastEditedDate DESC;
