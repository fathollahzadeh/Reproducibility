
WITH StringData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(clr.Name, 'Not Closed') AS CloseReason,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsString
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        CloseReasonTypes clr ON CAST(ph.Comment AS INTEGER) = clr.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, clr.Name
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    TagsString,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    CloseReason,
    CASE 
        WHEN CHAR_LENGTH(Body) > 500 THEN 'Long Body' 
        ELSE 'Short Body' 
    END AS BodyLengthCategory,
    EXTRACT(EPOCH FROM (CAST('2024-10-01 12:34:56' AS timestamp) - CreationDate)) AS AgeInSeconds
FROM 
    StringData
ORDER BY 
    AgeInSeconds DESC
LIMIT 10;
