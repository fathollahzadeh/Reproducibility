WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1  
),
TaggedPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.Tags,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        tp.CreationDate,
        string_agg(t.TagName, ', ') AS TagList
    FROM 
        TopPosts tp
    JOIN 
        Tags t ON t.TagName = ANY(string_to_array(tp.Tags, '><'))
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.Tags, tp.CommentCount, tp.UpVotes, tp.DownVotes, tp.CreationDate
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CreationDate,
    tp.TagList
FROM 
    TaggedPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC
LIMIT 10;