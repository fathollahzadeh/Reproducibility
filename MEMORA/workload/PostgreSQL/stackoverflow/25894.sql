
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS Rank 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp 
JOIN 
    Users u ON u.Id = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = rp.PostId
    )
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(rp.Tags, '><')) AS tagArray ON TRUE
JOIN 
    Tags t ON t.TagName = tagArray 
WHERE 
    rp.Rank <= 5
GROUP BY 
    u.DisplayName, rp.PostId, rp.Title, rp.CommentCount, rp.AnswerCount, rp.UpVotes, rp.DownVotes
ORDER BY 
    rp.CommentCount DESC, rp.AnswerCount DESC;
