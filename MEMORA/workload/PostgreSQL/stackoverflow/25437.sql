
WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        TagCount,
        UpVoteCount,
        DownVoteCount,
        CommentCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS RankByViews,
        RANK() OVER (ORDER BY UpVoteCount DESC) AS RankByUpVotes
    FROM 
        PostTagStats
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.TagCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.CommentCount,
    tp.RankByViews,
    tp.RankByUpVotes,
    pt.Name AS PostHistoryType
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    tp.RankByViews <= 10 OR tp.RankByUpVotes <= 10
ORDER BY 
    tp.RankByViews, tp.RankByUpVotes;
