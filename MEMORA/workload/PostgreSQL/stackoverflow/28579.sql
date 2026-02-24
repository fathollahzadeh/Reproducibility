
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ROW_NUMBER() OVER (ORDER BY rp.UpVotes - rp.DownVotes DESC, rp.CommentCount DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Body,
    tp.Tags,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.UpVotes - tp.DownVotes > 0 THEN 'Popular'
        WHEN tp.UpVotes - tp.DownVotes < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS Sentiment,
    U.DisplayName AS AuthorName,
    COUNT(b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT t.TagName) AS RelatedTags
FROM 
    TopPosts tp
JOIN 
    Users U ON tp.PostId = U.Id
LEFT JOIN 
    Badges b ON U.Id = b.UserId
LEFT JOIN 
    LATERAL (SELECT UNNEST(string_to_array(tp.Tags, ',')) AS TagName) AS tag ON true
LEFT JOIN 
    Tags t ON t.TagName = tag.TagName
WHERE 
    tp.Rank <= 10
GROUP BY 
    tp.Title, tp.CreationDate, tp.Body, tp.Tags, tp.CommentCount, tp.UpVotes, tp.DownVotes, U.DisplayName
ORDER BY 
    tp.UpVotes - tp.DownVotes DESC, tp.CommentCount DESC;
