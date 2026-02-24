
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(LAG(p.Id) OVER (ORDER BY p.CreationDate), p.Id), -1) AS PreviousPostId,
        COALESCE(NULLIF(LEAD(p.Id) OVER (ORDER BY p.CreationDate), p.Id), -1) AS NextPostId,
        (SELECT COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) 
         FROM Votes v 
         WHERE v.PostId = p.Id) AS UpVoteCount,
        (SELECT COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) 
         FROM Votes v 
         WHERE v.PostId = p.Id) AS DownVoteCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= '2023-01-01'
        AND p.Title IS NOT NULL
),
TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        TRIM(UNNEST(string_to_array(Tags, '><')))
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.CreationDate,
        fp.ViewCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        tt.TagName
    FROM 
        FilteredPosts fp
    JOIN 
        TopTags tt ON fp.Tags LIKE CONCAT('%', tt.TagName, '%')
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    CONCAT('Tag: ', pd.TagName) AS Details,
    CASE
        WHEN pd.UpVoteCount > pd.DownVoteCount THEN 'Positive'
        WHEN pd.UpVoteCount < pd.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC, 
    pd.ViewCount DESC;
