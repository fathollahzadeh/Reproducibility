
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        pt.Name AS PostTypeName,
        COALESCE(b.Count, 0) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags b ON p.Tags LIKE CONCAT('%<', b.TagName, '>%')
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name, b.Count
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, CommentCount, UpVotes, DownVotes, PostTypeName, TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName, 
    CommentCount,
    UpVotes,
    DownVotes,
    PostTypeName,
    TagCount
FROM 
    TopRankedPosts
ORDER BY 
    PostTypeName, UpVotes DESC;
