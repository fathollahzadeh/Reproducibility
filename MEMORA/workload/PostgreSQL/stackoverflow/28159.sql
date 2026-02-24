
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        t.TagName,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankByScore,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS RankByRecency
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, t.TagName, u.DisplayName, p.Title, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        TagName,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        RankByScore,
        RankByRecency
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
       OR RankByRecency <= 10 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    STRING_AGG(fp.TagName, ', ') AS Tags,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes
FROM 
    FilteredPosts fp
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.CreationDate DESC, fp.UpVotes DESC;
