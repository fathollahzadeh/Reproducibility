
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.Tags
), FilteredPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostTypeName,
        vt.Name AS VoteTypeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON pt.Id = 1
    LEFT JOIN 
        VoteTypes vt ON vt.Id = rp.UpVoteCount
    WHERE 
        rp.TagRank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.PostTypeName,
    fp.VoteTypeName
FROM 
    FilteredPosts fp
WHERE 
    fp.ViewCount > 1000
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
