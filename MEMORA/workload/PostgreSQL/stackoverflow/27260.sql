
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        users.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Users users ON p.OwnerUserId = users.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, users.DisplayName, pt.Name, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
TagStats AS (
    SELECT 
        pd.PostId,
        STRING_AGG(tt.TagName, ', ') AS TopTags
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    JOIN 
        TopTags tt ON tt.TagName = ANY(string_to_array(p.Tags, ','))
    GROUP BY 
        pd.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    pd.PostType,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.HistoryCount,
    COALESCE(ts.TopTags, 'N/A') AS TopTags
FROM 
    PostDetails pd
LEFT JOIN 
    TagStats ts ON pd.PostId = ts.PostId
ORDER BY 
    pd.ViewCount DESC,
    pd.UpVotes DESC
LIMIT 50;
