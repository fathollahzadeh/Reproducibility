
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY UpVotes DESC, CommentCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    PostId,
    Title,
    OwnerName,
    UpVotes,
    DownVotes,
    CommentCount,
    BadgeCount,
    LastActivityDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(tp.Tags, '>')) AS TagName
    ) t ON TRUE
WHERE 
    Rank <= 10  
GROUP BY 
    PostId, Title, OwnerName, UpVotes, DownVotes, CommentCount, BadgeCount, LastActivityDate
ORDER BY 
    UpVotes DESC, CommentCount DESC;
