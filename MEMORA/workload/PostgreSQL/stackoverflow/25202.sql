
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
        AND p.PostTypeId = 1 
        AND p.Body IS NOT NULL
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        TagName
),
MaxTagStats AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
PostRankings AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerDisplayName,
        fp.CommentCount,
        fp.UpVoteCount,
        COALESCE(mt.Rank, 0) AS TagRank
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        MaxTagStats mt ON fp.Tags LIKE '%' || mt.TagName || '%'
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.OwnerDisplayName,
    pr.CommentCount,
    pr.UpVoteCount,
    pr.TagRank
FROM 
    PostRankings pr
WHERE 
    pr.TagRank <= 5
ORDER BY 
    pr.UpVoteCount DESC, pr.CommentCount DESC;
