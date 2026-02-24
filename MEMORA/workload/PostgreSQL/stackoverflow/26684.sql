WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')'), ', ') AS Commenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, p.ViewCount
),
RecentQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.ViewCount,
        rp.CommentCount,
        rp.Commenters
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 AND rp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
),
KeywordTagCount AS (
    SELECT 
        unnest(string_to_array(t.TagName, ',')) AS Tag,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    rq.Title,
    rq.CreationDate,
    rq.ViewCount,
    rq.CommentCount,
    rq.Commenters,
    kt.Tag,
    kt.PostCount
FROM 
    RecentQuestions rq
LEFT JOIN 
    KeywordTagCount kt ON rq.Tags LIKE '%' || kt.Tag || '%'
ORDER BY 
    rq.ViewCount DESC, rq.CreationDate DESC;