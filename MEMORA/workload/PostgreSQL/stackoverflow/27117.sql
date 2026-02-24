
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days' 
        AND p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),

TagAggregates AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        TagName
),

RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tags,
        fp.CreationDate,
        fp.ViewCount,
        fp.OwnerDisplayName,
        fp.PostTypeName,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        ROW_NUMBER() OVER (ORDER BY fp.ViewCount DESC, (fp.UpVotes - fp.DownVotes) DESC) AS Rank
    FROM 
        FilteredPosts fp
)

SELECT 
    rp.*,
    ta.TagName,
    ta.PostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAggregates ta ON rp.Tags LIKE '%' || ta.TagName || '%'
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank, ta.PostCount DESC;
