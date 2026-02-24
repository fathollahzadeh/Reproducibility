
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(TRIM(BOTH '<>' FROM Tags), '>')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 1 
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerName,
    pd.CreationDate,
    pd.Upvotes,
    pd.Downvotes,
    pd.CommentCount,
    pd.BadgeCount,
    tt.TagName AS MostPopularTag,
    tt.PostCount AS TagUsageCount
FROM 
    PostDetails pd
LEFT JOIN 
    TopTags tt ON pd.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    pd.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR' 
ORDER BY 
    pd.Upvotes DESC, pd.CommentCount DESC, pd.CreationDate DESC;
