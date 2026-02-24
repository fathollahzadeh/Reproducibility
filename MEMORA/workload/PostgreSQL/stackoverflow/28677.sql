
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC, COUNT(DISTINCT v.UserId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON TRIM(tag) = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
    JOIN 
        Tags t ON TRIM(tag) = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    pt.TagName AS PopularTag,
    rph.Editors,
    rph.LastEditDate,
    rp.Rank
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(rp.Tags)
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId = rp.PostId
WHERE 
    rp.Rank <= 50 
ORDER BY 
    rp.Rank;
