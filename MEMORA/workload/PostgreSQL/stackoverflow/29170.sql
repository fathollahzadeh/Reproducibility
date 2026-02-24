
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT UNNEST(string_to_array(p.Tags, '><')) AS TagName) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
MostActiveUser AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS NumberOfPosts
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        NumberOfPosts DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        p.CommentCount,
        p.Tags
    FROM 
        RankedPosts p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.OwnerDisplayName IN (SELECT OwnerDisplayName FROM MostActiveUser)
    GROUP BY 
        p.PostId, p.Title, p.Score, p.CommentCount, p.Tags
)
SELECT 
    ps.Title,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.Tags
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC,
    ps.UpVotes DESC,
    ps.CommentCount DESC;
