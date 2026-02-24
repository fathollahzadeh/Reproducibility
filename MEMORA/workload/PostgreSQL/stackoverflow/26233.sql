
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        RANK() OVER (ORDER BY COALESCE(v.UpVoteCount, 0) - COALESCE(v.DownVoteCount, 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
),

FrequentTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM unnest(string_to_array(Tags, '>'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    rt.Tag,
    rt.TagCount
FROM 
    RankedPosts rp
JOIN 
    FrequentTags rt ON rp.Tags LIKE '%' || rt.Tag || '%'
WHERE 
    rp.VoteRank <= 10 
ORDER BY 
    rp.VoteRank, rt.TagCount DESC;
