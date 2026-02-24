
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        t.TagName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(COUNT(ph.Id), 0) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = (SELECT MIN(Id) FROM Tags WHERE Tags.ExcerptPostId = p.Id)
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, t.TagName
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC, CommentCount DESC, CreationDate ASC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    rp.Rank,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Author,
    rp.TagName,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.EditHistoryCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
